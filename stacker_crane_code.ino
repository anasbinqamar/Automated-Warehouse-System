//Communication-----------------------------------------------

#include <RH_ASK.h>
#ifdef RH_HAVE_HARDWARE_SPI
#include <SPI.h> // Not actually used but needed to compile
#endif


RH_ASK driver(2000, 8, 38, 0); // (speed, rx, tx, pos)
uint8_t buf[10];
uint8_t buflen = sizeof(buf);

uint8_t placing_area = 0; //'1' means filled
int wait = 0;
//------------------------------------------------------------

//LIFTER MOTOR-------------------
int R_EN1 = A5;
int L_EN1 = A4;
int RPWM1 = 2;
int LPWM1 = 3;
int PWM_UP = 90;
int PWM_DOWN = 60;
int PWM_UP_MAX = 90;
int PWM_DOWN_MAX = 60;
int PWM_UP_MIN = 70;
int PWM_DOWN_MIN = 20;
int REED_OUT = 45; //green
int REED_IN = 49; //back
//HORIZONTAL MOTOR--------------------------------------------
/*float C1_H = 10.5;
  float C2_H = 65.0;
  float R2_V = 13.6; */
int R_EN3 = A3;
int L_EN3 = A2;
int RPWM3 = 4;
int LPWM3 = 5;
int PWM_LEFT = 160;
int PWM_RIGHT = 160;
int PWM_LEFT_MAX = 160;
int PWM_RIGHT_MAX = 160;
//SPECIAL SPEED CONTROL
int PWM_LEFT_MIN =  160;
int PWM_RIGHT_MIN = 160;
//-----------------------------------------------------

//FORK MOTOR----------------------------------------------------
int R_EN2 = A1;
int L_EN2 = A0;
int RPWM2 = 10; //was 13
int LPWM2 = 9; //was 12
int PWM2 = 72; //pwm for fork
//-----------------------------------------------------------------

//SENSOR VERTICAL --------------------------------------------------
// min value is 5.6 -- 5.8(when lifter at bottom)
float setvalue; //correspond it to sensor output when it's at req. position <<<<<<<<<<<<<<<--------------------------------S E T P O I N T----------<<<
float adder; //sensor reading
const int trigPin = 23; //ORANGE
const int echoPin = 22; //RED  (
// defines variables
float duration;
float distance;
float tolerance = 0.18; //+ - TOLERANCE!
float prev_duration = 0;

//TASK CONTROL-------------------------------------------------------
/*Col 1: 7.51
  Col 2: 32.17
  Col 3: 60.11
  Col 4: 85

  Row 1: 65.4
  Row 2: 40.12
  Row 3:  13.6*/
float row[] = {0, 60.3, 40.12, 13.6}; //starts from n = 1
float column[] = {0, 7.51, 32.17, 60.11, 85};






//-------------------------------------------------------------------

int task = -4;
//SENSOR HORIZONTAL--------------------------------------------------
// min value is 7.5 -- max is 71.0 -- HORIZONTAL!!
float setvalue1; //correspond it to sensor output when it's at req. position <<<<<<<<<<<<<<<--------------------------------S E T P O I N T----------<<<
float adder1; //sensor reading
unsigned long timeout1 = 6000;
const int trigPin1 = 15; //ORANGE= purple
const int echoPin1 = 14; //RED = blue
// defines variables
float duration1;
float distance1;
float tolerance1 = 0.75; //+ - ------------------------------- T   O   L   E   R   A   N   C   E
float prev_duration1 = 0;
// -----------------------------------------------------------------

//Rack Detection


void setup() {
  //Communication---------------------------
#ifdef RH_HAVE_SERIAL
  Serial.begin(9600);    // Debugging only
#endif
  if (!driver.init())
#ifdef RH_HAVE_SERIAL
    Serial.println("init failed");
#else
    ;
#endif
  //-----------------------------------------
  //HORIZONTAL MOTOR SETUP
  pinMode(R_EN3, OUTPUT);
  pinMode(L_EN3, OUTPUT);
  pinMode(RPWM3, OUTPUT);
  pinMode(LPWM3, OUTPUT);
  digitalWrite(R_EN3, HIGH);
  digitalWrite(L_EN3, HIGH);
  //--------------------------

  //LIFTER MOTOR SETUP
  pinMode(R_EN1, OUTPUT);
  pinMode(L_EN1, OUTPUT);
  pinMode(RPWM1, OUTPUT);
  pinMode(LPWM1, OUTPUT);
  digitalWrite(R_EN1, HIGH);
  digitalWrite(L_EN1, HIGH);
  //--------------------------

  //FORK MOTOR SETUP
  pinMode(REED_OUT, INPUT_PULLUP);
  pinMode(REED_IN, INPUT_PULLUP);
  pinMode(R_EN2, OUTPUT);
  pinMode(L_EN2, OUTPUT);
  pinMode(RPWM2, OUTPUT);
  pinMode(LPWM2, OUTPUT);
  digitalWrite(R_EN2, HIGH); //Give R Enable pin to HIGH
  digitalWrite(L_EN2, HIGH); //Give L Enable pin to HIGH
  //--------------------------

  //SENSOR HORIZONTAL SETUP
  pinMode(trigPin1, OUTPUT);
  pinMode(echoPin1, INPUT);
  //--------------------------

  //SENSOR VERTICAL SETUP
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  //--------------------------

  Serial.begin(9600);
}

void loop() {
  recieveData();
  if(task == 1){
    Serial.print(wait);
    Picking(wait);
    }

};

void Vertical_Action(int setvalue) {
  //Serial.println(PWM3);
  readsensor(); //read sensor value horizontal
  if (adder < setvalue - tolerance) {
    GO_UP();
  }
  else if (adder > setvalue + tolerance) {
    GO_DOWN();
  }

  else if (adder > setvalue - tolerance &&  adder < setvalue + tolerance) {
    STOP_VERTICAL();
    delay(1000);
    readsensor();
    PWM_UP = PWM_UP_MIN;
    PWM_DOWN = PWM_DOWN_MIN;
    if (setvalue - tolerance < adder && setvalue + tolerance > adder) {
      task++;
      PWM_UP = PWM_UP_MAX; //reset PWM
      PWM_DOWN = PWM_DOWN_MAX; //reset PWM
    }
  }
};

void Horizontal_Action(int setvalue1) {
  readsensor1(); //read sensor value horizontal
  //HORIZONTAL MOTOR ACTION
  if (adder1 > setvalue1 + tolerance1) { //lifter at the right of the setvalue
    GO_LEFT(); //towards the sensor
  }
  else if (adder1 < setvalue1 - tolerance1) { //lifter at the left of the setvalue
    GO_RIGHT(); //away from the sensor
  }
  else if (adder1 > setvalue1 - tolerance1 &&  adder1 < setvalue1 + tolerance1) {
    STOP_HORIZONTAL(); //stop horizontal motor
    delay(1000);
    readsensor1(); //reread sensor
    PWM_LEFT = PWM_LEFT_MIN; //slow PWM
    PWM_RIGHT = PWM_RIGHT_MIN; //slow PWM
    if (adder1 > setvalue1 - tolerance1 &&  adder1 < setvalue1 + tolerance1) {
      STOP_HORIZONTAL();
      PWM_LEFT = PWM_LEFT_MAX; //reset PWM
      PWM_RIGHT = PWM_RIGHT_MAX; //reset PWM
      task++;
    }
  }
};

void FORK_PICKING() {

  //FORK COMES OUT AND STOPS--------------------
  while (digitalRead(REED_OUT) == HIGH) {
    Serial.println(REED_OUT);
    Serial.println(REED_IN);
    FORK_OUT();
  }
  STOP_FORK();
  delay(800);

  //VM GOES UP A BIT------------------------------
  GO_UP();
  delay(3100);
  STOP_VERTICAL();
  delay(1000);
  //FORK GOES BACK---------------------------------
  while (digitalRead(REED_IN) == HIGH) {
    FORK_IN();
  }
  STOP_FORK();
  delay(800);
  task++;
  Serial.println("FORK!");
};

void FORK_PLACING() {
  //VM GOES UP A BIT------------------------------
  GO_UP();
  delay(830);
  STOP_VERTICAL();
  delay(1000);
  //FORK COMES OUT AND STOPS--------------------
  while (digitalRead(REED_OUT) == HIGH) {
    FORK_OUT();
  }
  STOP_FORK();
  delay(1000);
  //VM GOES DOWN A BIT------------------------------
  GO_DOWN();
  delay(590);
  STOP_VERTICAL();
  delay(1000);
  //FORK GOES BACK---------------------------------
  while (digitalRead(REED_IN) == HIGH) {
    FORK_IN();
  }
  STOP_FORK();
  delay(800);
  task++;
  Serial.println("FORK!");
};

void readsensor1() {
  adder1 = 0;
  //reads from the horizontal sensor
  for (int x = 0; x < 50; x++) {
    // Clears the trigPin1
    digitalWrite(trigPin1, LOW);
    delayMicroseconds(2);
    // Sets the trigPin1 on HIGH state for 10 micro seconds
    digitalWrite(trigPin1, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin1, LOW);
    // Reads the echoPin1, returns the sound wave travel time in microseconds
    duration1 = pulseIn(echoPin1, HIGH, 6000); //wait until reading is 100!

    if (duration1 == 0) {
      duration1 = prev_duration1; //if nothing is read, set it to prevoius reading
    }
    // Calculating the distance (in cm)
    distance1 = duration1 * 0.034 * 0.5;
    prev_duration1 = duration1;
    adder1 = adder1 + distance1;
    delayMicroseconds(3000);
  }
  adder1 = adder1 / 50;
  Serial.print("Distance: ");
  Serial.println(adder1);

  //SENSOR READING ENDS---------------------------------------------------------------------------------------------
};

void readsensor() {
  adder = 0;
  //reads from the horizontal sensor
  for (int x = 0; x < 50; x++) {
    // Clears the trigPin
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    // Sets the trigPin on HIGH state for 10 micro seconds
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    // Reads the echoPin, returns the sound wave travel time in microseconds
    duration = pulseIn(echoPin, HIGH, 6000); //wait until reading is 100!

    if (duration == 0) {
      duration = prev_duration; //if nothing is read, set it to prevoius reading
    }
    // Calculating the distance (in cm)
    distance = duration * 0.034 * 0.5;
    prev_duration = duration;
    adder = adder + distance;
    delayMicroseconds(3000);
  }
  adder = adder / 50;
  Serial.print("Distance: ");
  Serial.println(adder);

  //SENSOR READING ENDS---------------------------------------------------------------------------------------------
};


void GO_LEFT() {
  analogWrite(RPWM3, 0); // STOP THE MOTOR FIRST
  analogWrite(LPWM3, PWM_LEFT); //if you want to GO LEFT
  Serial.print("LEFT");
};

void GO_RIGHT() {
  analogWrite(LPWM3, 0); //STOP THE MOTOR FIRST
  analogWrite(RPWM3, PWM_RIGHT); //if you want to GO RIGHT
  Serial.print("RIGHT");
};

void STOP_HORIZONTAL() {
  analogWrite(LPWM3, 0); // STOP THE MOTOR FIRST
  analogWrite(RPWM3, 0); //if you want to STOP
  Serial.print("STOP!");
};

void GO_UP() {
  analogWrite(RPWM1, 0); //STOP THE MOTOR FIRST
  analogWrite(LPWM1, PWM_UP); //if you want to GO UP
  Serial.print("GO UP!");
};

void GO_DOWN() {
  analogWrite(LPWM1, 0); // STOP THE MOTOR FIRST
  analogWrite(RPWM1, PWM_DOWN); //if you want to GO DOWN
  Serial.print("GO DOWN!");
};

void STOP_VERTICAL() {
  analogWrite(LPWM1, 0); // STOP THE MOTOR FIRST
  analogWrite(RPWM1, 0); //if you want to STOP
  Serial.print("STOP!");
};

void FORK_OUT() {
  analogWrite(RPWM2, 0); //FORK COMES OUT
  analogWrite(LPWM2, PWM2); //if you want to
};

void FORK_IN() {
  analogWrite(LPWM2, 0); //STOP THE MOTOR FIRST
  analogWrite(RPWM2, PWM2); //FORK GOES BACK
};



void STOP_FORK() {
  analogWrite(RPWM2, 0); //FORK STOPS OUT
  analogWrite(LPWM2, 0); //if you want to
};
void FREEZE() { //STOPS EVERYTHING!
  STOP_VERTICAL();
  STOP_HORIZONTAL();
  STOP_FORK();
};
void Picking(int address) {
  //address to row/col conversion---
  int row_add = (address / 4) + 1;
  int col_add = (address % 4) + 1;
  //address to row/col completed----
  int a = task;
  while (task == a) {
    Horizontal_Action(column[col_add]);
    Serial.print(wait);
    }
  a = task;
  while (task == a) {
    Vertical_Action(row[row_add]);
  }
  a = task;
  while (task == a) {
    FORK_PICKING();
  }
  a = task;
  while (task = a) {
    Vertical_Action(row[2]);
  }
  a = task;
  while (task = a) {
    Horizontal_Action(column[1]);
  }
  a = task;
  while (task = a) {
    FORK_PLACING();
  }
  task = 0;
};

void recieveData() {
  /*This is the Reiceiving Data Function---
    There are three different types of data to be received:
    1. PWM Speed (for Hor, and Ver. System) (e.g, P155)
    2. Address to be Retrieved (i.e, R0 -- R11)
    3. A signal for whether the placing area is filled (i.e, Z1/Z0)
    Note:
    1. You'll have to buffer if one retrieving is ongoing and the other is sent!
    2. You'll need to make sure that placing area is empty, before proceeding with receiving! (just add it to buffer if filled)
    3. You'll need to recieve info regarding picking area as well
  */
  if (driver.recv(buf, &buflen)) // Non-blocking - check if data is available
  {
    String rcv = ""; //clear the string
    for (int i = 0; i < buflen; i++) {
      rcv += (char)buf[i];
    }
    if (rcv.charAt(0) == 'P') {
      rcv.remove(0, 1); //remove 1 char starting from index 0 of string rcv
      int dait = rcv.toInt(); //store recv value in int
      //Serial.println(wait);
    }
    else if (rcv.charAt(0) == 'R') {
      rcv.remove(0, 1); //remove 1 char starting from index 0 of string rcv
       wait = rcv.toInt(); //store recv value in int
      task = 1;
      //Serial.println(wait);
    }
    else if (rcv.charAt(0) == 'Z') {
      rcv.remove(0, 1); //remove 1 char starting from index 0 of string rcv
      placing_area = rcv.toInt(); //store recv value in int
      //Serial.println(wait);
    }
  }
};
