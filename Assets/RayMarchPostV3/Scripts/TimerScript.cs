using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimerScript : MonoBehaviour
{
    RaymarchPostProcess postProcess;
    private float startTime;
    private int len;

    void Start()
    {
        postProcess = GameObject.FindObjectOfType<RaymarchPostProcess>();
        startTime = Time.time;
        len = postProcess.sphereColorVector.Length;
    }

    void Update()
    {
        if (!postProcess.repeatable)
        {
            postProcess.t = (Time.time - startTime) * postProcess.colorLerpTime;
        }
        else
        {
            //t = (Mathf.Sin(Time.time - startTime) * colorLerpTime); // periodic time interpolation
            // Debug.Log(postProcess.t);

            postProcess.t = Mathf.Lerp(postProcess.t, 1f, postProcess.colorLerpTime * (Time.deltaTime - startTime));
            if (postProcess.t > .99f)
            {
                postProcess.t = 0f;
                if (postProcess.colorIndexE == len - 1)
                {
                    postProcess.colorIndexS = postProcess.colorIndexE;
                    postProcess.colorIndexE = 0;
                }
                else
                {
                    postProcess.colorIndexS = postProcess.colorIndexE;
                    postProcess.colorIndexE++;
                }
            }
        }
    }
}
