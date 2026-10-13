-- ---------------------------------------------------------------------------------------------------------------------
-- Logic Implementation for the 74LS162, 4-Bit Decade Counter
-- this one is functionally identically to the 74LS161 but it only counts to 9
-- legit, yk for decimal displays and binary coded decimal and stuff
-- its useful, like, i promise it really is
-- who tf am i arguing with
-- /red - 2026-05-24
-- ---------------------------------------------------------------------------------------------------------------------
function PropertySetup()

    addIntegerSliderProperty("Count", 0, 9, 0)
end

function PinSetup()

    -- power pins are just gonna be inputs
    pins.VCC.output = PIN_INPUT;
    pins.GND.output = PIN_INPUT;

    -- all them inputs
    pins.CLR .output = PIN_INPUT;
    pins.CLK .output = PIN_INPUT;
    pins.A   .output = PIN_INPUT;
    pins.B   .output = PIN_INPUT;
    pins.C   .output = PIN_INPUT;
    pins.D   .output = PIN_INPUT;
    pins.ENP .output = PIN_INPUT;
    pins.LOAD.output = PIN_INPUT;
    pins.ENT .output = PIN_INPUT;

    -- all them outputs
    pins.QA  .output = PIN_OUTPUT;
    pins.QB  .output = PIN_OUTPUT;
    pins.QC  .output = PIN_OUTPUT;
    pins.QD  .output = PIN_OUTPUT;
    pins.RCO .output = PIN_OUTPUT;

end

-- ---------------------------------------------------------------------------------------------------------------------
rippleCarry = false
-- ---------------------------------------------------------------------------------------------------------------------

function Step()

    -- if CLR low -> instantly clear the state and output
    if pins.CLR.input == PIN_LOW then
        properties.Count = 0;
        rippleCarry = false;
    else
        -- if the output is 1001 and the pin ENT is high -> turn on ripple carry
        rippleCarry = properties.Count == 9 and pins.ENT.input == 1;
    end

    updatePins();
end

-- ---------------------------------------------------------------------------------------------------------------------

function StepRising()

    -- if CLR low -> instantly clear the state and output
    -- this has the highest priority! nothing else comes after
    if pins.CLR.input == PIN_LOW then

        -- just clear the state, then end this step
        properties.Count = 0;
        rippleCarry = false;
        updatePins();

        return;
    end

    -- if LOAD is low
    -- -> load the value from the inputs
    if pins.LOAD.input == PIN_LOW then
        properties.Count = BinToNum({
            pins.D.input,
            pins.C.input,
            pins.B.input,
            pins.A.input,
        });

        updatePins();
        return;
    end

    -- if ENP and ENT are high
    -- -> counting is enabled, count!
    if pins.ENP.input == PIN_HIGH and pins.ENT.input == PIN_HIGH then
        properties.Count = properties.Count + 1;

        -- have we reached to counters target?
        if properties.Count > 9 then
            properties.Count = 0      -- roll over
        end
    end

    updatePins();
end

-- ---------------------------------------------------------------------------------------------------------------------

function updatePins()

    state = NumToBin(properties.Count, 4);
    pins.QA .output = state[4];
    pins.QB .output = state[3];
    pins.QC .output = state[2];
    pins.QD .output = state[1];
    pins.RCO.output = rippleCarry;
end

-- ---------------------------------------------------------------------------------------------------------------------

function LoadState(state)
    properties.Count = state["num"];
    rippleCarry      = state["rippleCarry"];
end

function SaveState()
    return {
        num = properties.Count,
        rippleCarry = rippleCarry
    };
end