#ifndef Encoder_h
#define Encoder_h
#define TICKS 48;

volatile int count;

void ISR_enc()
{
  count++;
}

class Encoder{
  private:
    int PinA, PinB;
    double duration, speed, RPM;
  public:
    Encoder(int pinA, int pinB) {PinA = pinA; PinB = pinB;}
    double GetEncoder(){
      // Set PinA for INPUT to read count of pulses from encoder
      pinMode(PinA, INPUT);
      pinMode(PinB, INPUT);
      // Tic the pulse in PinA by polling
      // Polling method
      /*
      duration = pulseIn(PinA, HIGH);
      if (digitalRead(PinB == LOW))
      {
        // Means the motor has rotated inversely
        return -duration;
      }
      else
      {
        return duration;
      }
      */
      // Interrupt method
      attachInterrupt(digitalPinToInterrupt(PinA), ISR_enc, RISING);
      RPM = (count/0.01)*60/TICKS;
      // Calculate speed m/s
      speed = (RPM * 3.141592653/10) / 60;
      return speed;
    }
};
#endif