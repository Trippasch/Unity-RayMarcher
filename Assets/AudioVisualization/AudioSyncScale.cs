using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

public class AudioSyncScale : AudioSyncer
{
    public float beatScale;
    public float restScale;

    private RaymarchPostProcess pp;
    private PostProcessVolume volume;

    private void Start()
    {
        volume = GetComponent<PostProcessVolume>();
        volume.profile.TryGetSettings<RaymarchPostProcess>(out pp);
    }

    public override void OnUpdate()
    {
        base.OnUpdate();

        if (m_isBeat) return;

        pp.scaleBox.value = Mathf.Lerp(pp.scaleBox.value, restScale, restSmoothTime * Time.deltaTime);
    }

    public override void OnBeat()
    {
        base.OnBeat();

        StopCoroutine("MoveToScale");
        StartCoroutine("MoveToScale", beatScale);
    }

    private IEnumerator MoveToScale(float _target)
    {
        float _curr = pp.scaleBox.value;
        float _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Mathf.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            pp.scaleBox.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }
}