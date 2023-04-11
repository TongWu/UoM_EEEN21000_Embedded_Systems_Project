#ifndef Encoder_h
#define Encoder_h
int TICKS = 48;

volatile int count;

void ISR_enc()
{
  count += 1;
}

class Encoder
{
private:
  int PinA, PinB;
  double duration, speed, RPM;
  double millis_;
  double millis_pre = 0;

public:
  Encoder(int pinA, int pinB)
  {
    PinA = pinA;
    PinB = pinB;
  }
  double GetEncoder()
  {
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
    millis_ = millis();
    attachInterrupt(digitalPinToInterrupt(PinA), ISR_enc, RISING);
    // Set a sampling time for 0.01s
      millis_pre = millis_;
      RPM = (float)count / (TICKS);
      // Calculate speed m/s
      // speed = (RPM * 3.141592653 / 10) / 60;
      // return speed;
      return RPM;
  }

  void count_zero()
  {
    count = 0;
  }
};
#endif