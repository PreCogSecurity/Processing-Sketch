/*
  Graph by Thomas Sanchez Lengeling

  show the incomming values from a FFT sound analyzer.

  RELIABILITY FIX: the sketch read Serial.list()[0] unconditionally, so opening
  it with no Arduino attached threw ArrayIndexOutOfBoundsException at startup
  and the sketch was unusable. The port list is now checked, the device is
  selected explicitly, and the port is released on exit so the device is not
  held after the sketch closes.
*/
import java.util.*;
import java.util.concurrent.*;

import processing.serial.*;

Serial port;

// Set true in the IDE, or set the ARDUINO_PORT environment variable, to pick a
// device other than the first one found.
String requestedPort = System.getenv("ARDUINO_PORT");

GraphBar   gpPitch;

PFont font;

color fontColor = color(200);

void setup() {
  size(540, 220);
  smooth(4);

  //USB PORT
  String[] available = Serial.list();
  if (requestedPort == null || requestedPort.trim().isEmpty()) {
    if (available.length == 0) {
      println("NO SERIAL DEVICE FOUND");
      println("Plug in an Arduino and press Run again, or set ARDUINO_PORT.");
      // Leave the graph running so the window is still inspectable.
      return;
    }
    requestedPort = available[0];
  }
  port = new Serial(this, requestedPort, 9600);
  println("SERIAL DEVICE " + requestedPort);

  //FUENTE
  font = createFont("Monospaced.plain", 17);
  textFont(font);

  //GRAFICAS
  gpPitch   = new GraphBar("Pitch", 20, 100, 100, 200);
  gpPitch.setLabel("1023", "0");
  gpPitch.setFontColor(fontColor);
}


void draw() {
  background(35);

  if (gpPitch == null) {
    return;
  }

  gpPitch.draw();

  if (port != null && port.available() > 0) {
    float val = port.read();
    gpPitch.updateLog(val);
  }
}

public void exit() {
  if (port != null) {
    port.stop();
    port = null;
  }
  super.exit();
}

void mouseDragged() {
  if (gpPitch == null) {
    return;
  }
  gpPitch.setSliderValue(mouseX, mouseY);
}

void mousePressed() {
  if (gpPitch == null) {
    return;
  }
  gpPitch.setSliderValue(mouseX, mouseY);
}


void mouseReleased() {
  if (gpPitch == null) {
    return;
  }
  gpPitch.sliderOff();
}

