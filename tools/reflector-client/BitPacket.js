class BitPacket
{
    constructor(width, notify)
    {
        if (typeof(width) === "string")
        {
            this._width = width.length;
            this._buffer = Buffer.alloc(BitPacket.byteCountForBitWidth(this._width));
            this.bits = width;
        }
        else
        {
            this._width = width;
            this._buffer = Buffer.alloc(BitPacket.byteCountForBitWidth(this._width));
            this._buffer[0] = 0x80;
        }
        if (notify)
            this.notify = notify;
    }

    get width() 
    { 
        return this._width 
    };

    getBits(msb, lsb)
    {
        // Check bit range
        if (msb < 0 || msb > this.width ||
            lsb < 0 || lsb > this.width ||
            msb < lsb)
            throw new Error("invalid bit range");

        return this.bits.substr(this.width - msb-1, msb - lsb + 1);
    }
    
    setBits(msb, lsb, value)
    {
        // Check bit range
        if (msb < 0 || msb > this.width ||
            lsb < 0 || lsb > this.width ||
            msb < lsb)
            throw new Error("invalid bit range");

        // Check length matches
        if (msb - lsb + 1 != value.length)
            throw new Error("value length doesn't match bit range");

        let oldBits = this.bits;
        this.bits = `${oldBits.substr(0, this.width - msb - 1)}${value}${oldBits.substr(this.width - lsb)}`;
    }

    get bits() 
    { 
        return this.toString() 
    };

    set bits(value) 
    {
        if (value.length != this._width)
            throw new Error(`Bit count mismatch (expected ${this._width}, not ${value.length}`);

        // Encode
        value = value.padStart(this._buffer.length * 7, '0');
        for (let i=0; i<this._buffer.length; i++)
        {
            let subbits = value.substr(-7 - i * 7, 7);
            this._buffer[i] = parseInt(subbits, 2) | (i==0 ? 0x80 : 0);
        }

        if (this.notify)
            this.notify();
    }

    toString()
    {
        let bits = "";
        for (let i=this._buffer.length-1; i>=0; i--)
        {
            bits += (this._buffer[i] & 0x7f).toString(2).padStart(7, '0');
        }

        return bits.substr(-this._width);
    }

    static byteCountForBitWidth(bitWidth)
    {
        return Math.floor((bitWidth + 6) / 7);
    }


    // Helper to enumerate the bit positions of a word bit range within a serial packet
    static *getBitPositions(msb, lsb)
    {
        let startBytePos = Math.floor(lsb / 7);
        let endBytePos = Math.floor(msb / 7);
        let shiftPacket = 0;
        for (let i=startBytePos; i<=endBytePos; i++)
        {
            let startBitPos = i == startBytePos ? (lsb % 7) : 0;
            let endBitPos = i == endBytePos ? (msb % 7) : 6;

            yield { 
                byte: i, 
                shiftByte: startBitPos, 
                mask: Math.pow(2, endBitPos - startBitPos + 1) - 1, 
                shiftPacket,
                startBitPos, 
                endBitPos
            }

            shiftPacket += endBitPos - startBitPos + 1;
        }
    }

    static buildGetAccessorBody(packet, msb, lsb)
    {
        let fnGet = "";
        for (let i of BitPacket.getBitPositions(msb,lsb))
        {
            if (fnGet.length > 0)
                fnGet += " | ";
            
            let el = `buffer[${i.byte}]`;
            if (i.shiftByte != 0)
                el = `(${el} >> ${i.shiftByte})`;
            if (i.mask != 0x7F || i.byte == 0)
                el = `(${el} & 0x${i.mask.toString(16).toUpperCase()})`
            if (i.shiftPacket != 0)
                el = `(${el} << ${i.shiftPacket})`;
            fnGet += el;
        }
        return `    let buffer = ${packet}._buffer; return ${fnGet};`;
    }
    
    static buildSetAccessorBody(packet, msb, lsb, name)
    {
        let fnSet =  `let buffer = ${packet}._buffer;\n`;

//        let checkMask = Math.pow(2, msb - lsb + 1) - 1;
//        fnSet += `    if ((value & 0x${checkMask.toString(16).toUpperCase()}) != value)\n`;
//        fnSet += '        throw new Error(`value 0x${value.toString(16).toUpperCase()} out of range for accessor "' + name + '" defined as (' + msb + '..' + lsb + ').`);\n';

        for (let i of BitPacket.getBitPositions(msb,lsb))
        {
            let oldValueMasked;
            if ((i.mask << i.shiftByte) != 0x7f)
                oldValueMasked = `(buffer[${i.byte}] & 0x${(0xFF ^ (i.mask << i.shiftByte)).toString(16).toUpperCase()}) | `;
            else
                oldValueMasked = i.byte == 0 ? `0x80 | ` : "";
        
            let el = `value`;
            if (i.shiftPacket != 0)
                el = `(${el} >> ${i.shiftPacket})`;
            if (i.mask != 0xFF)
                el = `(${el} & 0x${i.mask.toString(16).toUpperCase()})`;
            if (i.shiftByte != 0)
                el = `(${el} << ${i.shiftByte})`;
        
            fnSet += `    buffer[${i.byte}] = ${oldValueMasked}${el};\n`
        }

        fnSet += `    if (${packet}.notify) ${packet}.notify()`;
        return fnSet;
    }
    
    static defineAccessor(obj, name, msb, lsb)
    {
        // Define properties
        Object.defineProperty(obj, name, {
            get: Function([], BitPacket.buildGetAccessorBody("this", msb, lsb)),
            set: Function(['value'], BitPacket.buildSetAccessorBody("this.buffer", msb, lsb, name)),
        });
    }

}


module.exports = BitPacket;