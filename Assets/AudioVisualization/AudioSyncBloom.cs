using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

public class AudioSyncBloom : AudioSyncer
{
    public float beatScale;
    public float restScale;

    private Bloom bloom;
    private PostProcessVolume volume;

    private void Start()
    {
        volume = GetComponent<PostProcessVolume>();
        volume.profile.TryGetSettings<Bloom>(out bloom);
    }

    public override void OnUpdate()
    {
        base.OnUpdate();

        if (m_isBeat) return;

        bloom.intensity.value = Mathf.Lerp(bloom.intensity.value, restScale, restSmoothTime * Time.deltaTime);
    }

    public override void OnBeat()
    {
        base.OnBeat();

        StopCoroutine("MoveToScale");
        StartCoroutine("MoveToScale", beatScale);
    }

    private IEnumerator MoveToScale(float _target)
    {
        float _curr = bloom.intensity.value;
        float _initial = _curr;
        float _timer = 0;

        while (_curr != _target)
        {
            _curr = Mathf.Lerp(_initial, _target, _timer / timeToBeat);
            _timer += Time.deltaTime;

            bloom.intensity.value = _curr;

            yield return null;
        }

        m_isBeat = false;
    }
}