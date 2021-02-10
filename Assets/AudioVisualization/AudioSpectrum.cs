using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Mini "engine" for analyzing spectrum data
/// Feel free to get fancy in here for more accurate visualizations!
/// </summary>
public class AudioSpectrum : MonoBehaviour
{
    // Unity fills this up for us
    private float[] m_audioSpectrum;

    // This value served to AudioSyncer for beat extraction
    public static float spectrumValue {get; private set;}

    private void Start()
    {
        // initialize buffer
        m_audioSpectrum = new float[128];
    }

    private void Update()
    {
        // get the data
        AudioListener.GetSpectrumData(m_audioSpectrum, 0, FFTWindow.Hamming);

        // assign spectrum value
        // this "engine" focuses on the simplicity of other classes only..
        // ..needing to retrieve one value (spectrumValue)
        if (m_audioSpectrum != null && m_audioSpectrum.Length > 0)
        {
            spectrumValue = m_audioSpectrum[0] * 100;
        }
    }
}
