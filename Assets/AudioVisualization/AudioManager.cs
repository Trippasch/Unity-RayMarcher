// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using UnityEngine.Audio;

// [RequireComponent (typeof (AudioSource))]
// public class AudioManager : MonoBehaviour
// {
//     private AudioSource audioSource;

//     private float[] samplesLeft = new float[512];
//     private float[] samplesRight = new float[512];

//     //audio 8
//     private float[] freqBand = new float[8];
//     private float[] bandBuffer = new float[8];
//     private float[] bufferDecrease = new float[8];
//     private float[] freqBandHighest = new float[8];

//     [HideInInspector]
//     public float[] audioBand, audioBandBuffer;

//     //audio 64
//     private float[] freqBand64 = new float[64];
//     private float[] bandBuffer64 = new float[64];
//     private float[] bufferDecrease64 = new float[64];
//     private float[] freqBandHighest64 = new float[64];

//     [HideInInspector]
//     public float[] audioBand64, audioBandBuffer64;

//     [HideInInspector]
//     public static float amplitude, amplitudeBuffer;
//     private float amplitudeHighest;

//     public float audioProfile;

//     public enum channel {Stereo, Left, Right};
//     public channel _channel = new channel();

//     public AudioClip audioClip;

//     // Microphone Input
//     public bool useMicrophone;
//     public string selectedDevice;
//     public AudioMixerGroup mixerGroupMicrophone, mixerGroupMaster;

//     // Awake is called when the script instance is being loaded.
//     // void Awake() {
//     //     QualitySettings.vSyncCount = 0;  // VSync must be disabled
//     //     Application.targetFrameRate = 60;
//     // }

//     // Start is called before the first frame update
//     void Start()
//     {
//         audioBand = new float[8];
//         audioBandBuffer = new float[8];

//         audioBand64 = new float[64];
//         audioBandBuffer64 = new float[64];

//         audioSource = GetComponent<AudioSource>();
//         AudioProfile(audioProfile);

//         if (useMicrophone)
//         {
//             if (Microphone.devices.Length > 0)
//             {
//                 selectedDevice = Microphone.devices[0].ToString();
//                 audioSource.outputAudioMixerGroup = mixerGroupMicrophone;
//                 audioSource.clip = Microphone.Start(selectedDevice, true, 10, AudioSettings.outputSampleRate);
//             }
//             else
//             {
//                 useMicrophone = false;
//             }
//         }
//         else
//         {
//             audioSource.outputAudioMixerGroup = mixerGroupMaster;
//             audioSource.clip = audioClip;
//         }

//         audioSource.Play();
//     }

//     // Update is called once per frame
//     void Update()
//     {
//         GetSpectrumAudioSource();
//         MakeFrequencyBands();
//         MakeFrequencyBands64();
//         BandBuffer();
//         BandBuffer64();
//         CreateAudioBands();
//         CreateAudioBands64();
//         GetAmplitude();
//     }

//     void AudioProfile(float audioProfile)
//     {
//         for (int i = 0; i < 8; i++)
//         {
//             freqBandHighest[i] = audioProfile;
//         }
//     }

//     void GetAmplitude()
//     {
//         float currentAmplitude = 0;
//         float currentAmplitudeBuffer = 0;

//         for (int i = 0; i < 8; i++)
//         {
//             currentAmplitude += audioBand[i];
//             currentAmplitudeBuffer += audioBandBuffer[i];
//         }

//         if (currentAmplitude > amplitudeHighest)
//         {
//             amplitudeHighest = currentAmplitude;
//         }

//         amplitude = currentAmplitude / amplitudeHighest;
//         amplitudeBuffer = currentAmplitudeBuffer / amplitudeHighest;
//     }

//     void GetSpectrumAudioSource()
//     {
//         audioSource.GetSpectrumData(samplesLeft, 0, FFTWindow.Blackman);
//         audioSource.GetSpectrumData(samplesRight, 1, FFTWindow.Blackman);
//     }

//     void CreateAudioBands() {// create values between zero and one that can be apllied to a lot of different outputs
//         for (int i = 0; i < 8; i++)
//         {
//             if (freqBand[i] > freqBandHighest[i])
//             {
//                 freqBandHighest[i] = freqBand[i];
//             }
//             audioBand[i] = (freqBand[i] / freqBandHighest[i]);
//             audioBandBuffer[i] = (bandBuffer[i] / freqBandHighest[i]);
//         }
//     }

//     void CreateAudioBands64() {// create values between zero and one that can be apllied to a lot of different outputs
//         for (int i = 0; i < 64; i++)
//         {
//             if (freqBand64[i] > freqBandHighest64[i])
//             {
//                 freqBandHighest64[i] = freqBand64[i];
//             }
//             audioBand64[i] = (freqBand64[i] / freqBandHighest64[i]);
//             audioBandBuffer64[i] = (bandBuffer64[i] / freqBandHighest64[i]);
//         }
//     }

//     void BandBuffer() {
//         for (int g = 0; g < 8; g++)
//         {
//             if (freqBand[g] > bandBuffer[g])
//             {
//                 bandBuffer[g] = freqBand[g];
//                 bufferDecrease[g] = .005f;
//             }
//             if (freqBand[g] < bandBuffer[g])
//             {
//                 bandBuffer[g] -= bufferDecrease[g];
//                 bufferDecrease[g] *= 1.2f;
//             }
//         }
//     }

//     void BandBuffer64() {
//         for (int g = 0; g < 64; g++)
//         {
//             if (freqBand64[g] > bandBuffer64[g])
//             {
//                 bandBuffer64[g] = freqBand64[g];
//                 bufferDecrease64[g] = .005f;
//             }
//             if (freqBand64[g] < bandBuffer64[g])
//             {
//                 bandBuffer64[g] -= bufferDecrease64[g];
//                 bufferDecrease64[g] *= 1.2f;
//             }
//         }
//     }

//     void MakeFrequencyBands()
//     {
//         /*
//         *  22050 / 512 = 43hz per sample
//         *  
//         *  20 - 60hz
//         *  60 - 250hz
//         *  250 - 500hz
//         *  2000 - 4000hz
//         *  4000 - 6000hz
//         *  6000 - 20000hz
//         *  
//         *  0 - 2 = 86hz
//         *  1 - 4 = 172hz - 87-258
//         *  2 - 8 = 344hz - 259-602
//         *  3 - 16 = 688hz - 603-1290
//         *  4 - 32 = 1376hz - 1291-2666
//         *  5 - 64 = 2752hz - 2667-5418
//         *  6 - 128 = 5504hz - 5419-10922
//         *  7 - 256 = 11008hz - 10923-21930
//         *  510
//         */
//         int count = 0;
//         for ( int i = 0; i < 8; i++ )
//         {
//             float average = 0;
//             int sampleCount = (int)Mathf.Pow( 2, i ) * 2;
//             if ( i == 7 )
//             {
//                 sampleCount += 2;
//             }
//             for ( int j = 0; j < sampleCount; j++ )
//             {
//                 if (_channel == channel.Stereo)
//                 {
//                     average += (samplesLeft[count] + samplesRight[count]) * ( count + 1 );
//                 }
//                 else if (_channel == channel.Left)
//                 {
//                     average += (samplesLeft[count]) * ( count + 1 );
//                 }
//                 else if (_channel == channel.Right)
//                 {
//                     average += (samplesRight[count]) * ( count + 1 );
//                 }
//                 count++;
//             }
//             average /= count;
//             freqBand[i] = average * 10;
//         }
//     }

//     void MakeFrequencyBands64()
//     {
//         int count = 0;
//         int sampleCount = 1;
//         int power = 0;

//         for ( int i = 0; i < 64; i++ )
//         {
//             float average = 0;

//             if (i == 16 || i == 32 || i == 40 || i == 48 || i == 56)
//             {
//                 power++;
//                 sampleCount = (int)Mathf.Pow( 2, power);
//                 if (power == 3)
//                 {
//                     sampleCount -= 2;
//                 }
//             }
//             for (int j = 0; j < sampleCount; j++)
//             {
//                 if (_channel == channel.Stereo)
//                 {
//                     average += (samplesLeft[count] + samplesRight[count]) * ( count + 1 );
//                 }
//                 else if (_channel == channel.Left)
//                 {
//                     average += (samplesLeft[count]) * ( count + 1 );
//                 }
//                 else if (_channel == channel.Right)
//                 {
//                     average += (samplesRight[count]) * ( count + 1 );
//                 }
//                 count++;
//             }
//             average /= count;
//             freqBand64[i] = average * 80;
//         }
//     }
// }
