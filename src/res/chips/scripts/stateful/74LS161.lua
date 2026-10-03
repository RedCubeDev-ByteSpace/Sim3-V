-- ---------------------------------------------------------------------------------------------------------------------
-- Logic Implementation for the 74LS161, 4-Bit Binary Counter
-- /red - 2026-05-21
-- ---------------------------------------------------------------------------------------------------------------------
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
num = 0
rippleCarry = false
-- ---------------------------------------------------------------------------------------------------------------------

function Step()

    -- if CLR low -> instantly clear the state and output
    if pins.CLR.input == PIN_LOW then
        num = 0;
        rippleCarry = false;
    else
        -- if the output is 1111 and the pin ENT is high -> turn on ripple carry
        rippleCarry = num == 15 and pins.ENT.input == 1;
    end

    updatePins();
end

-- ---------------------------------------------------------------------------------------------------------------------

function StepRising()

    -- if CLR low -> instantly clear the state and output
    -- this has the highest priority! nothing else comes after
    if pins.CLR.input == PIN_LOW then

        -- just clear the state, then end this step
        num = 0;
        rippleCarry = false;
        updatePins();

        return;
    end

    -- if LOAD is low
    -- -> load the value from the inputs
    if pins.LOAD.input == PIN_LOW then
        num = BinToNum({
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
        num = num + 1;

        -- have we overflown our 4 bits?
        if num > 15 then
            num = 0      -- roll over
        end
    end

    updatePins();
end

-- ---------------------------------------------------------------------------------------------------------------------

function updatePins()

    state = NumToBin(num, 4);
    pins.QA .output = state[4];
    pins.QB .output = state[3];
    pins.QC .output = state[2];
    pins.QD .output = state[1];
    pins.RCO.output = rippleCarry;
end

-- ---------------------------------------------------------------------------------------------------------------------

function LoadState(state)
    num         = state["num"];
    rippleCarry = state["rippleCarry"];
end

function SaveState()
    return {
        num = num,
        rippleCarry = rippleCarry
    };
end