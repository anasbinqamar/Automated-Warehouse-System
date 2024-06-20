/**
 * Simple Read
 * 
 * Read data from the serial port and change the color of a rectangle
 * when a switch connected to a Wiring or Arduino board is pressed and released.
 * This example works with the Wiring / Arduino program that follows below.
 */


import processing.serial.*;
import controlP5.*;

PImage homescreen;

ControlP5 control, home; //create an object of ControlP5 library
Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port

Slider motor;
Button PWM, silver, retrieve, setting;
int SPEED = 130;

char read_ir[] = {'1', '0', '0', '0', '1', '0', '0', '1', '0', '0', '0', '0' }; //sensor array
int x_rack = 0, y_rack = 0;
int currentPage = 0;


void setup() 
{//1366 x 768 display
  //size(1366, 768);
  fullScreen();
  homescreen = loadImage("blue_metal.jpg");
  homescreen.resize(width, height);
  background(0);
  home = new ControlP5(this);
  control = new ControlP5(this);
  ControlFont cf1 = new ControlFont(createFont("Arial", 20, true));

//Home Page-----------------
retrieve = home.addButton("Retrieve").setPosition(500, 100)
    .setColorActive(color(#0000FF, 255)).setFont(cf1).setLabel("RETRIEVE"). setSize(200, 70) 
    .setColorBackground(color(#0000FF,50)).setColorForeground(color(#0000FF,50));
  //Slider---------------------
  motor = control.addSlider("SPEED").setBroadcast(false).setPosition(800, 50).setRange(80, 255).setValue(120).setHeight(50).setWidth(200)
    .setColorActive(color(225, 232, 233)).setColorForeground(color(225, 232, 233)).setColorBackground(color(104, 104, 104))
    .setCaptionLabel("").setValueLabel("").setBroadcast(true); //Speed Control Slider

  //Button------------------------
  silver = control.addButton("SET_SPEED").setPosition(1100, 50)
    .setColorActive(color(111, 111, 111  )).setFont(cf1).setLabel("SPEED"). setSize(100, 50) 
    .setColorBackground(color(0, 0, 255)).setColorForeground(color(0, 0, 255));

  



  myPort = new Serial(this, "COM9", 9600);   //serial initializationx
}

void draw()
{ 
  if(currentPage == 1){
  background(homescreen);
  control.hide();
  }
  if(currentPage == 0){
  background(0);
  drawRack(x_rack, y_rack);
 /* if (myPort.available() > 0) 
  {  // If data is available,
    val = myPort.readStringUntil('\n');         // read it and store it in val
    // println(val); //print it out in the console
    read_ir = val.toCharArray(); //stores string in a char array
  } */
}
}

void drawRack(int x, int y) {
  for (int j = 0; j < 3; j++)
  {
    for (int i = 0; i<4; i++) {
      if (read_ir[(j*4) + i] == '0') {
        fill(190, 252, 198); //Green
      } else {
        fill(252, 190, 209); //Red
      }
      rect(x + 30 + 110*i, y + 20 + 110*j, 100, 100, 15);
    }
  }
}

void SPEED(int theColor) { //if SLDER IS MOVED
  SPEED = theColor;
  println("a slider event. setting background to "+theColor);
  silver.show();
}

public void SET_SPEED() { //IF BUTTON IS PRESSED

  println("a button event from colorA: ");
  silver.hide();
  String send;
  println(SPEED);
  send = "<S" + SPEED + ">";
  send = send + send + send + send + send;
  println(send);
}

void mouseClicked() {// Integer.toString(int) --convert int into string -- another: String result = "" + a + b + c + d + e --appends int to strings! Same thing for appending chars!

  for (int j = 0; j < 3; j++) // this loop checks for click on boxes and sends it to arduino
  {
    for (int i = 0; i<4; i++) {
      if (mouseX > (x_rack + 30 + 110*i) && mouseX < (x_rack + 130 + 110*i) && mouseY > (y_rack + 20 + 110*j) && mouseY < (y_rack + 120 +110*j) ) 
      { //check for each box click
        String send = ""; //empty out the string
        int a = 4*j + i; //box number
        if (read_ir[a] == '1') { //only sent retrieve command if empty
          send = "<" + "R" + "0" + a + ">"; 
          send += send + send + send + send + send;
          myPort.write(send);
          println(send);
        }
      }
    }
  }
}
