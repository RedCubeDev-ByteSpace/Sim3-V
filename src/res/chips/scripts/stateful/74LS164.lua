-- ---------------------------------------------------------------------------------------------------------------------
-- Logic Implementation for the 74LS164, 8-Bit Shift Register
-- /red - 2026-10-13
-- ---------------------------------------------------------------------------------------------------------------------

function PinSetup()

    -- power pins are just gonna be inputs
    pins.VCC.output = PIN_INPUT;
    pins.GND.output = PIN_INPUT;

    -- all them inputs
    pins.CLR.output = PIN_INPUT;
    pins.CLK.output = PIN_INPUT;
    pins.A  .output = PIN_INPUT;
    pins.B  .output = PIN_INPUT;

    -- all them outputs
    pins.QA .output = PIN_OUTPUT;
    pins.QB .output = PIN_OUTPUT;
    pins.QC .output = PIN_OUTPUT;
    pins.QD .output = PIN_OUTPUT;
    pins.QE .output = PIN_OUTPUT;
    pins.QF .output = PIN_OUTPUT;
    pins.QG .output = PIN_OUTPUT;
    pins.QH .output = PIN_OUTPUT;

end

-- ---------------------------------------------------------------------------------------------------------------------
qa = False
qb = False
qc = False
qd = False
qe = False
qf = False
qg = False
qh = False
-- ---------------------------------------------------------------------------------------------------------------------

function Step()

    -- if CLR low -> instantly clear the state and output
    if pins.CLR.input == PIN_LOW then
        qa = False
        qb = False
        qc = False
        qd = False
        qe = False
        qf = False
        qg = False
        qh = False
    end

    updatePins();
end

-- ---------------------------------------------------------------------------------------------------------------------

function StepRising()

    -- determine the next state to shift in
    nextState = pins.A.input == PIN_HIGH and pins.B.input == PIN_HIGH;

    -- shift it through
    qh = qg;
    qg = qf;
    qf = qe;
    qe = qd;
    qd = qc;
    qc = qb;
    qb = qa;
    qa = nextState;

    -- update the outputs
    updatePins();
end

-- ---------------------------------------------------------------------------------------------------------------------

function updatePins()
    pins.QA.output = qa;
    pins.QB.output = qb;
    pins.QC.output = qc;
    pins.QD.output = qd;
    pins.QE.output = qe;
    pins.QF.output = qf;
    pins.QG.output = qg;
    pins.QH.output = qh;
end

-- ---------------------------------------------------------------------------------------------------------------------

function LoadState(state)
    qa = state["qa"];
    qb = state["qb"];
    qc = state["qc"];
    qd = state["qd"];
    qe = state["qe"];
    qf = state["qf"];
    qg = state["qg"];
    qh = state["qh"];
end

function SaveState()
    return {
        qa = qa,
        qb = qb,
        qc = qc,
        qd = qd,
        qe = qe,
        qf = qf,
        qg = qg,
        qh = qh
    };
end