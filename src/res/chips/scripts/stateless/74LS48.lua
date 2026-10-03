-- ---------------------------------------------------------------------------------------------------------------------
-- Logic Implementation for the 74LS48, Binary-Coded-Decimal to seven segment display converter
-- /red - 2026-05-24
-- ---------------------------------------------------------------------------------------------------------------------
function PinSetup()

    -- power pins!! just set them as input idek
    pins.VCC.output = PIN_INPUT;
    pins.GND.output = PIN_INPUT;

    -- all BDC Pins are all inputs
    pins.A.output = PIN_INPUT;
    pins.B.output = PIN_INPUT;
    pins.C.output = PIN_INPUT;
    pins.D.output = PIN_INPUT;

    -- LampTest is also a input
    pins.LT.output = PIN_INPUT;

    -- BlankingInput / RippleBlankingOutput is a little special because its both input and output
    -- -> by default its a floating input, but turns into a low output once RippleBlankingInput is low
    pins.BIRB.output = PIN_INPUT;

    -- RippleBlankingInput is always an input
    pins.RBI.output = PIN_INPUT;

    -- the rest are the seven segment outputs
    pins.a.output = PIN_OUTPUT;
    pins.b.output = PIN_OUTPUT;
    pins.c.output = PIN_OUTPUT;
    pins.d.output = PIN_OUTPUT;
    pins.e.output = PIN_OUTPUT;
    pins.f.output = PIN_OUTPUT;
    pins.g.output = PIN_OUTPUT;
end

function Step()

    -- BlankingInput has priority
    if pins.BIRB.input == PIN_LOW and pins.BIRB.output ~= PIN_LOW then
        setPinsFor(15);
        return;
    end

    -- Next up: LampTest
    if pins.LT.input == PIN_LOW then
        -- turn on all lamps, meaning: display an 8
        setPinsFor(8);
        return;
    end

    -- decode the number thats currently set on the inputs
    num = BinToNum({
        pins.D.input, pins.C.input, pins.B.input, pins.A.input
    });

    -- Then: process RippleBlankingInput (+ Leading/Trailing Zero suppression)
    if pins.RBI.input == PIN_LOW and num == 0 then

        -- turn off all lamps
        setPinsFor(15);

        -- ripple it down the line
        pins.BIRB.output = PIN_LOW;

        return;
    end

    -- last but not least, just output the number
    setPinsFor(num);

    -- also reset RBO if theres no blanking going on anymore
    pins.BIRB.output = PIN_INPUT;
end

-- for some reason this chip supports outputting unique shapes for all
-- combinations from 0 to 15 - everything after 9 does not resemble a digit tho
-- may still be very helpful for debugging hex things
lookupTable = {
    {1, 1, 1, 1, 1, 1, 0}, -- 0
    {0, 1, 1, 0, 0, 0, 0}, -- 1
    {1, 1, 0, 1, 1, 0, 1}, -- 2
    {1, 1, 1, 1, 0, 0, 1}, -- 3
    {0, 1, 1, 0, 0, 1, 1}, -- 4
    {1, 0, 1, 1, 0, 1, 1}, -- 5
    {0, 0, 1, 1, 1, 1, 1}, -- 6 -- i didnt make a mistake, the 6 on this thing looks like a lowercase b
    {1, 1, 1, 0, 0, 0, 0}, -- 7
    {1, 1, 1, 1, 1, 1, 1}, -- 8
    {1, 1, 1, 0, 0, 1, 1}, -- 9 -- again, slightly weird way of showing a 9, looks like a q, i blame the americans

    {0, 0, 0, 1, 1, 0, 1}, -- 10
    {0, 0, 1, 1, 0, 0, 1}, -- 11
    {0, 1, 0, 0, 0, 1, 1}, -- 12
    {1, 0, 0, 1, 0, 1, 1}, -- 13
    {0, 0, 0, 1, 1, 1, 1}, -- 14
    {0, 0, 0, 0, 0, 0, 0}, -- 15 -- entirely blank
};

function setPinsFor(num)
    setPinsToTable(lookupTable[num + 1]);
end

function setPinsToTable(states)
    pins.a.output = states[1];
    pins.b.output = states[2];
    pins.c.output = states[3];
    pins.d.output = states[4];
    pins.e.output = states[5];
    pins.f.output = states[6];
    pins.g.output = states[7];
end