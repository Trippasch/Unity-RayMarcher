using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

public class AudioSyncColorGradient : AudioSyncer
{
    public float postExpBeatScale;
    public float postExpRestScale;

    public float hueBeatScale;
    public float hueRestScale;

    public float tempBeatScale;
    public float tempRestScale;

    public float saturateBeatScale;
    public float saturateRestScale;

    public Vector4 gammaBeatScale;
    public Vector4 gammaRestScale;

    private ColorGrading cgradient;
    private PostProcessVolume volume;

    private void Start()
    {
        volume = GetComponent<PostProcessVolume>();
        volume.profile.TryGetSettings<ColorGrading>(out cgradient);
    }

    public override void OnUpdate()
    {
        base.OnUpdate();

        if (m_isBeat) return;

        cgradient.postExposure.value = Mathf.Lerp(cgradient.postExposure.value, postExpRestScale, restSmoothTime * Time.deltaTime);
        cgradient.hueShift.value = Mathf.Lerp(cgradient.hueShift.value, hueRestScale, restSmoothTime * Time.deltaTime);
        cgradient.temperature.value = Mathf.Lerp(cgradient.temperature.value, tempRestScale, restSmoothTime * Time.deltaTime);
        cgradient.saturation.value = Mathf.Lerp(cgradient.saturation.value, saturateRestScale, restSmoothTime * Time.deltaTime);
        cgradient.gamma.value = Vector4.Lerp(cgradient.gamma.value, gammaRestScale, restSmoothTime * Time.deltaTime);
    }

    public override void OnBeat()
    {
        base.OnBeat();

        StopCoroutine("MoveToScalePost");
        StartCoroutine("MoveToScalePost", postExpBeatScale);

        StopCoroutine("MoveToScaleHue");
        StartCoroutine("MoveToScaleHue", hueBeatScale);

        StopCoroutine("MoveToScaleTemp");
        StartCoroutine("MoveToScaleTemp", tempBeatScale);

        StopCoroutine("MoveToScaleSatureate");
        StartCoroutine("MoveToScaleSaturate", saturateBeatScale);

        StopCoroutine("MoveToScaleGamma");
        StartCoroutine("MoveToScaleGamma", gammaBeatScale);
    }

    private IEnumerator MoveToScalePost(float _target)
    {
        float _curr = cgradient.postExposure.value;
        float _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Mathf.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            cgradient.postExposure.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }

    private IEnumerator MoveToScaleHue(float _target)
    {
        float _curr = cgradient.hueShift.value;
        float _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Mathf.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            cgradient.hueShift.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }

    private IEnumerator MoveToScaleTemp(float _target)
    {
        float _curr = cgradient.temperature.value;
        float _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Mathf.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            cgradient.temperature.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }

    private IEnumerator MoveToScaleSaturate(float _target)
    {
        float _curr = cgradient.saturation.value;
        float _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Mathf.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            cgradient.saturation.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }

    private IEnumerator MoveToScaleGamma(Vector4 _target)
    {
        Vector4 _curr = cgradient.gamma.value;
        Vector4 _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Vector4.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            cgradient.gamma.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }
}
