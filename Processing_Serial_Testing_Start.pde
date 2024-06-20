import processing.serial.*; //import serial library
import controlP5.*; //import GUI library

PImage homescreen; //background image

ControlP5 control_speed, rack_page, main, tolerance_page, back; //create an object of ControlP5 library

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port

Slider motor_v, motor_h, tolerance_v, tolerance_h;
Button PWM, v_motor, h_motor, v_tolerance, h_tolerance, retrieve, setting, monitor_rack, back_button;

int SPEED_V = 130, SPEED_H = 130;
int TOLERANCE_V = 100, TOLERANCE_H = 100;

char read_ir[] = {'1', '0', '0', '0', '1', '0', '0', '1', '0', '0', '0', '0' }; //sensor array
int x_rack = 200, y_rack = 200; //set rack position
int currentPage = 0;


void setup() 
{
  //Initial Setup of Screen-----------------------------------------------------------
  //1366 x 768 display
  //size(1366, 768);
  fullScreen();
  homescreen = loadImage("depth.jpg");
  homescreen.resize(width, height);
  background(0);
  main = new ControlP5(this); //buttons for main page
  rack_page = new ControlP5(this);
  control_speed = new ControlP5(this);
  tolerance_page = new ControlP5(this);
  back = new ControlP5(this);
  ControlFont cf1 = new ControlFont(createFont("Arial", 20, true));
  //ControlFont title = new ControlFont(createFont("Arial", 70, true));
  //----------------------------------------------------------------------------------

  //Main Page-------------------------------------------------------------------------
  //Monitor Rack Button---------
  monitor_rack = main.addButton("Rack_Monitor")
    .setPosition(230, 220).setColorActive(color(#FFFFFF, 255)).setFont(cf1).setColorLabel(0).setLabel("Rack Monitor").setSize(900, 70) 
    .setColorBackground(color(#FFFFFF, 150)).setColorForeground(color(#FFFFFF, 200));
  //SpeedControl Button---------
  monitor_rack = main.addButton("Speed_Control")
    .setPosition(230, 310).setColorActive(color(#FFFFFF, 255)).setFont(cf1).setColorLabel(0).setLabel("Speed Control").setSize(900, 70) 
    .setColorBackground(color(#FFFFFF, 150)).setColorForeground(color(#FFFFFF, 200));
  //ToleranceControl Button-----
  monitor_rack = main.addButton("Tolerance_Control")
    .setPosition(230, 400).setColorActive(color(#FFFFFF, 255)).setFont(cf1).setColorLabel(0).setLabel("Tolerance Control").setSize(900, 70) 
    .setColorBackground(color(#FFFFFF, 150)).setColorForeground(color(#FFFFFF, 200));
  //Help Button-----------------
  monitor_rack = main.addButton("Help")
    .setPosition(230, 490).setColorActive(color(#FFFFFF, 255)).setFont(cf1).setColorLabel(0).setLabel("Help").setSize(900, 70)
    .setColorBackground(color(#FFFFFF, 150)).setColorForeground(color(#FFFFFF, 200));
  //----------------------------------------------------------------------------------

  //Rack Monitoring Page--------------------------------------------------------------
  retrieve = rack_page.addButton("Retrieve").setPosition(500, 100)
    .setColorActive(color(#0000FF, 255)).setFont(cf1).setLabel("RETRIEVE"). setSize(200, 70) 
    .setColorBackground(color(#0000FF, 50)).setColorForeground(color(#0000FF, 50));
  //----------------------------------------------------------------------------------

  //Speed_Control Page----------------------------------------------------------------
  //Motor_V Slider---------------------
  motor_v = control_speed.addSlider("SPEED_V").setBroadcast(false).setPosition(550, 220).setRange(80, 255).setValue(120).setHeight(50).setWidth(450)
    .setColorActive(color(#FFFFFF)).setColorForeground(color(225, 232, 233)).setColorBackground(color(100, 100, 100)).setLabelVisible(false) 
    .setCaptionLabel("").setValueLabel("").setBroadcast(true); //Speed Control Slider
  //V_Motor Button------------------------
  v_motor = control_speed.addButton("SET_SPEED_V").setPosition(1020, 220)
    .setColorActive(color(#FFFFFF)).setFont(cf1).setColorLabel(0).setLabel("SPEED"). setSize(100, 50) 
    .setColorBackground(color(#FFFFFF, 210)).setColorForeground(color(#FFFFFF, 240));
  //Motor_H Slider---------------------
  motor_h = control_speed.addSlider("SPEED_H").setBroadcast(false).setPosition(550, 290).setRange(80, 255).setValue(120).setHeight(50).setWidth(450)
    .setColorActive(color(#FFFFFF)).setColorForeground(color(225, 232, 233)).setColorBackground(color(100, 100, 100)).setLabelVisible(false) 
    .setCaptionLabel("").setValueLabel("").setBroadcast(true); //Speed Control Slider
  //H_Motor Button------------------------
  h_motor = control_speed.addButton("SET_SPEED_H").setPosition(1020, 290)
    .setColorActive(color(#FFFFFF)).setFont(cf1).setColorLabel(0).setLabel("SPEED"). setSize(100, 50) 
    .setColorBackground(color(#FFFFFF, 210)).setColorForeground(color(#FFFFFF, 240));
  //----------------------------------------------------------------------------------

  //Tolerance Control Page------------------------------------------------------------
  //Tolerance_V Slider-----------------------
  tolerance_v = tolerance_page.addSlider("TOLERANCE_V").setBroadcast(false).setPosition(550, 220).setRange(80, 255).setValue(120).setHeight(50).setWidth(450)
    .setColorActive(color(#FFFFFF)).setColorForeground(color(225, 232, 233)).setColorBackground(color(100, 100, 100)).setLabelVisible(false) 
    .setCaptionLabel("").setValueLabel("").setBroadcast(true); //Speed Control Slider
  //V_Tolerance Button-----------------------
  v_tolerance = tolerance_page.addButton("SET_TOLERANCE_V").setPosition(1020, 220)
    .setColorActive(color(#FFFFFF)).setFont(cf1).setColorLabel(0).setLabel("SET"). setSize(100, 50) 
    .setColorBackground(color(#FFFFFF, 210)).setColorForeground(color(#FFFFFF, 240));
  //Tolerance_H Slider-----------------------
  tolerance_h = tolerance_page.addSlider("TOLERANCE_H").setBroadcast(false).setPosition(550, 290).setRange(80, 255).setValue(120).setHeight(50).setWidth(450)
    .setColorActive(color(#FFFFFF)).setColorForeground(color(225, 232, 233)).setColorBackground(color(100, 100, 100)).setLabelVisible(false) 
    .setCaptionLabel("").setValueLabel("").setBroadcast(true); //Speed Control Slider
  //H_Tolerance Button-----------------------
  h_tolerance = tolerance_page.addButton("SET_TOLERANCE_H").setPosition(1020, 290)
    .setColorActive(color(#FFFFFF)).setFont(cf1).setColorLabel(0).setLabel("SET"). setSize(100, 50) 
    .setColorBackground(color(#FFFFFF, 210)).setColorForeground(color(#FFFFFF, 240));
  //--------------------------------------------------------------------------------

  //Universal Back Button (except for main page)----
  back_button = back.addButton("Back_Button")
    .setPosition(0, 0).setColorActive(color(111, 111, 111)).setFont(cf1).setLabel("<BACK")
    .setSize(100, 50).setColorBackground(color(0, 0, 255)).setColorForeground(color(0, 0, 255));



  //  myPort = new Serial(this, "COM9", 9600);   //serial initializationx
}

void draw()
{ 
  if (currentPage == 0) {
    mainScreen(); //draw mainScreen
  }
  if (currentPage == 1) {
    rackScreen(); //draw rackScreen
  }
  if (currentPage == 2) {
    speedScreen(); //draw speedScreen
  }
  if (currentPage == 3) {
    toleranceScreen(); //draw toleranceScreen
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



//Main Page Button Control Fucnctions----------------------------------------------------
void Rack_Monitor() {
  currentPage = 1;
}

void Speed_Control() {
  currentPage = 2;
}


void Tolerance_Control() {
  currentPage = 3;
}

void Help() {
  currentPage = 4;
}
//----------------------------------------------------------------------------------------

//Speed Page Button Control---------------------------------------------------------
void SPEED_V(int theColor) { //if SLDER IS MOVED
  SPEED_V = theColor;
  println("a slider event. setting background to "+theColor);
  v_motor.show();
}

public void SET_SPEED_V() { //IF BUTTON IS PRESSED
  println("a button event from colorA: ");
  v_motor.hide();
  String send;
  println(SPEED_V);
  send = "<SV" + SPEED_V + ">";
  println(send);
}

void SPEED_H(int theColor) { //if SLDER IS MOVED
  SPEED_H = theColor;
  println("a slider event. setting background to "+theColor);
  h_motor.show();
}

public void SET_SPEED_H() { //IF BUTTON IS PRESSED
  println("a button event from colorA: ");
  h_motor.hide();
  String send;
  println(SPEED_H);
  send = "<SH" + SPEED_H + ">";
  println(send);
}
//---------------------------------------------------------------------------------------

//Tolerance Page Button Control---------------------------------------------------------
void TOLERANCE_V(int theColor) { //if SLDER IS MOVED
  TOLERANCE_V = theColor;
  println("a slider event. setting background to "+theColor);
  v_tolerance.show();
}

public void SET_TOLERANCE_V() { //IF BUTTON IS PRESSED
  println("a button event from colorA: ");
  v_tolerance.hide();
  String send;
  println(TOLERANCE_V);
  send = "<TV" + TOLERANCE_V + ">";
  println(send);
}

void TOLERANCE_H(int theColor) { //if SLDER IS MOVED
  SPEED_H = theColor;
  println("a slider event. setting background to "+theColor);
  h_tolerance.show();
}

void SET_TOLERANCE_H() { //IF BUTTON IS PRESSED
  println("a button event from colorA: ");
  h_tolerance.hide();
  String send;
  println(SPEED_H);
  send = "<TH" + SPEED_H + ">";
  println(send);
}
//---------------------------------------------------------------------------------------


//Back_Button Function-----------------------
void Back_Button() {
  currentPage = 0;
}
//-------------------------------------------

//Rack Click Function---------------------------------------------
void mouseClicked() {// Integer.toString(int) --convert int into string -- another: String result = "" + a + b + c + d + e --appends int to strings! Same thing for appending chars!

  //Cick Function for Rack-------------------------------------------------------------------------------------------------------------------
  if (currentPage == 1) {
    for (int j = 0; j < 3; j++) // this loop checks for click on boxes and sends it to arduino
    {
      for (int i = 0; i<4; i++) {
        if (mouseX > (x_rack + 30 + 110*i) && mouseX < (x_rack + 130 + 110*i) && mouseY > (y_rack + 20 + 110*j) && mouseY < (y_rack + 120 +110*j) ) 
        { //check for each box click
          String send = ""; //empty out the string
          int a = 4*j + i; //box number
          if (read_ir[a] == '1') { //only sent retrieve command if empty
            send = "<" + "R" + "0" + a + ">"; 
            // myPort.write(send);
            println(send);
          }
        }
      }
    }
  }
  //-------------------------------------------------------------------------------------------------------------------ENDS
}

//Draw MainScreen------------------------------------------------
void mainScreen() {
  //background(homescreen);
  image(homescreen, 0, 0); //show background

  //hide unwanted buttons and show relevant ones
  control_speed.hide();
  rack_page.hide();
  tolerance_page.hide();
  back.hide();
  main.show();

  //draw top Rect and Write Title -------------------
  fill(0, 180);
  noStroke();
  rect(70, 0, width-150, 100, 0, 0, 100, 100);
  textSize(70);
  fill(230, 230, 230);
  text("Automated Warehouse System V1", 100, 70);

  //draw rect for button area------------
  fill(0, 150);
  rect(200, 190, width-400, height-370);

  //adding buttons--------------
}
//---------------------------------------------------------------

//Draw Rack Page-------------------------------------------------
void rackScreen() {
  //hide unwanted buttons and show relevant ones
  main.hide();
  control_speed.hide();
  tolerance_page.hide();
  back.show();
  rack_page.show();

  background(0);
  drawRack(x_rack, y_rack);
  /* if (myPort.available() > 0) 
   {  // If data is available,
   val = myPort.readStringUntil('\n');         // read it and store it in val
   // println(val); //print it out in the console
   read_ir = val.toCharArray(); //stores string in a char array
   } */
}
//--------------------------------------------------------------

//Draw Speed Control Screen ------------------------------------
void speedScreen() {
  background(homescreen);
  //rect(0, 0, width, height);
  //hide unwanted buttons and show relevant ones
  rack_page.hide();
  main.hide();
  back.show();
  control_speed.show();

  //draw rect for button area------------
  fill(0, 150);
  rect(200, 190, width-400, height-590);

  textSize(28);
  fill(230, 230, 230);
  text("Vertical Speed Control:", 220, 260);
  text("Horizon. Speed Control:", 220, 330);
}
//----------------------------------------------------------------

//Draw Tolerance Control Screen ----------------------------------
void toleranceScreen() {
  background(homescreen);
  //rect(0, 0, width, height);
  //hide unwanted buttons and show relevant ones
  rack_page.hide();
  control_speed.hide();
  main.hide();
  back.show();
  tolerance_page.show();


  //draw rect for button area------------
  fill(0, 150);
  rect(200, 190, width-400, height-590);

  textSize(28);
  fill(230, 230, 230);
  text("Vertical Tolerance:", 220, 260);
  text("Horizontal Tolerance:", 220, 330);
}
//----------------------------------------------------------------


