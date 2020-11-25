BEGIN {
    print "WIDTH=32;";
    print "DEPTH=512;";
    print;
    print "ADDRESS_RADIX=UNS;";
    print "DATA_RADIX=HEX;";
    print;
    print "CONTENT BEGIN";
    WORD_ADDR = 0;
}

$1 ~ /[0-9a-z]+:/ && $2 ~ /[0-9a-z]{8}/ {
    output = "    " WORD_ADDR " : " $2 ";    --"
    $1 = ""; $2 = "";
    output = output $0

    print output

    WORD_ADDR++;
}

END {
    print "    [" WORD_ADDR  "..511] : 00000000;"
    print "END;"
}