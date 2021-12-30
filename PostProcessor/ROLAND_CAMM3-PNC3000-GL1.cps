/**
  Roland CAMM-3 PNC-3000 post processor configuration.
*/

description = "Roland PNC3000 CAMM-GL1";
vendor = "Roland DG";
vendorUrl = "http://www.rolanddg.com";
legal = "free to use or modify";
certificationLevel = 2;
minimumRevision = 45704;

longDescription = "Post for the Roland CAMM-3 PNC3000 CNC Mill that outputs CAMM-GL1, an early version of Roland RML. By default the post will output code in the Metric 0.01 ticks the PNC-3000 expects for Z move commands.";

extension = "prn";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.005, MM);

minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion

// user-defined properties
properties = {
  machineType: {
    title      : "Machine type",
    description: "Sets the machine type.",
    type       : "enum",
    values     : [
      {id:"pnc3000", title:"PNC3000"},
    ],
    value: "pnc3000",
    scope: "post"
  }
};

var mFormat = createFormat({decimals:0});

var xyzFormat; // set in onOpen
var feedFormat = createFormat({decimals:(unit == MM ? 1 : 1), decimals:0, trim:true, scale:1.0 / 60});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var milliFormat = createFormat({decimals:0}); // milliseconds

var xOutput; // set in onOpen
var yOutput; // set in onOpen
var zOutput; // set in onOpen
var feedOutput = createVariable({}, feedFormat);
var sOutput = createVariable({force:true}, rpmFormat);

// collected state
var rapidFeed;
var sMin;
var sMax;

/**
  Writes the specified block.
*/
function writeBlock() {
  writeln(formatWords(arguments) + ";");
}

/**
  Returns the machine type.
*/
function getMachineType() {
  return String(getProperty("machineType")).toLowerCase();
}

function onOpen() {

  setWordSeparator("");

  writeBlock((getMachineType() == "pnc3000" ? "^DF" : "!0"));

  switch (getMachineType()) {
  case "pnc3000":
    rapidFeed = 22 * 60;
    step = 0.01;
    sMin = 4500;
    sMax = 4500;
    break;
  default:
    error(localize("No machine type is selected. You have to define a machine type using the properties."));
    return;
  }

  xyzFormat = createFormat({decimals:(unit == MM ? 0 : 0), scale:1.0 / step});
  xOutput = createVariable({force:true}, xyzFormat);
  yOutput = createVariable({force:true}, xyzFormat);
  zOutput = createVariable({force:true}, xyzFormat);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  feedOutput.reset();
}

function onParameter(name, value) {
}

function goHome() {
  feedOutput.reset(); // force V
  switch (String(getProperty("machineType")).toLowerCase()) {
    case "pnc3000":
    writeBlock("^PA");
    var rf = feedOutput.format(rapidFeed);
    writeBlock("V" + rf + ";F" + rf);
    break;
  }
  zOutput.reset();
}

function getSpindleSpeed() {
  var rpm = spindleSpeed;
  var speedCode = 0;
  var sDiff = sMax - sMin;

  var checkrpm = sMin;
  var middle = sMin;
  while (checkrpm < rpm) { // find the closest speedCode
    speedCode += 1;
    var nextSpindleSpeed = ((sDiff / 15) * speedCode) + sMin;
    middle = (nextSpindleSpeed - checkrpm) / 2;
    checkrpm += (nextSpindleSpeed - checkrpm);
  }
  if ((rpm + middle) < checkrpm) { // find the middle of spindle speed range
    speedCode -= 1;
  }
  return speedCode;
}

function getOperationComment() {
  var operationComment = hasParameter("operation-comment") && getParameter("operation-comment");
  return operationComment;
}

function onSection() {
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);

  var retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis());
  if (insertToolCall || newWorkOffset || newWorkPlane) {
    // retract to safe plane
    retracted = true;
    goHome(); //retract
  }

  if (insertToolCall) {
    if (!isFirstSection() && getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > 6) {
      warning(localize("Tool number exceeds maximum value."));
    }

    if (!isFirstSection()) {
        error(localize("Tool change is not supported. Please only post operations using the same tool."));
        return;
    }
  }

  if (insertToolCall ||
      isFirstSection() ||
      (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    if (spindleSpeed < sMin) {
      error(
        subst(localize("Spindle speed exceeds the minimum value for operation \"%1\"."), getOperationComment()) + " " +
        subst(localize("The spindle speed has to be between %1 and %2 RPM."), rpmFormat.format(sMin), rpmFormat.format(sMax))
      );
      return;
    }
    if (spindleSpeed > sMax) {
      error(
        subst(localize("Spindle speed exceeds the maximum value for operation \"%1\"."), getOperationComment()) + " " +
        subst(localize("The spindle speed has to be between %1 and %2 RPM."), rpmFormat.format(sMin), rpmFormat.format(sMax))
      );
      return;
    }
    writeBlock(
      "!1" // spindle on (M03)
    );
  }

  // wcs
  var workOffset = currentSection.workOffset;
  if (workOffset > 0) {
    // error(localize("Work offset out of range."));
    // return;
  }

  forceAny(); 

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      goHome();
      feedOutput.reset();
    }
  }

  if (insertToolCall) {
    writeBlock(
      "Z",
      xOutput.format(initialPosition.x), ",",
      yOutput.format(initialPosition.y), ",",
      zOutput.format(initialPosition.z)
    );
  }
}

function onSpindleSpeed(spindleSpeed) {
  if (spindleSpeed > 0) {
    writeBlock("!1");
  } else {
    writeBlock("!0");
  }
  
}

function onDwell(seconds) {
  if (seconds > 32767 / 1000.0) {
    warning(localize("Dwelling time is out of range."));
  }
  milliseconds = clamp(1, seconds * 1000, 32767);
  writeBlock("W", milliFormat.format(milliseconds));
}

function onRapid(_x, _y, _z) {
  if (radiusCompensation > 0) {
    error(localize("Radius compensation is not supported."));
    return;
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    var rf = feedOutput.format(rapidFeed);
    if (rf) {
      writeBlock("V" + rf + ";F" + rf); // rapid feed (like G0)
    }
    writeBlock("Z", x + ",", y + ",", z);
    feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  if (radiusCompensation > 0) {
    error(localize("Radius compensation is not supported."));
    return;
  }

  var f = feedOutput.format(feed);
  if (f) {
    writeBlock("V" + f + ";F" + f);
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    writeBlock("Z", x + ",", y + ",", z);
  }
}

function onCircular() {
  linearize(tolerance); // note: could use operation tolerance
}

function onCommand(command) {
  onUnsupportedCommand(command);
}

function onSectionEnd() {
  forceAny();
}

function onClose() {
  writeBlock("!0"); // stop spindle
  goHome();

  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
}

function setProperty(property, value) {
  properties[property].current = value;
}
