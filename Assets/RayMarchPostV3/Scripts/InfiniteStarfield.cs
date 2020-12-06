using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InfiniteStarfield : MonoBehaviour
{
    private Transform tx;
    private new ParticleSystem particleSystem;
    private ParticleSystem.Particle[] points;

    public int starsMax = 100;
    public float starSize = 1.0f;
    public float starDistance = 10.0f;
    private float starDistanceSqr;
    public float starClipDistance = 1.0f;
    private float starClipDistanceSqr;

    // Start is called before the first frame update
    void Start()
    {
        tx = transform;
        particleSystem = tx.GetComponent<ParticleSystem>();
        starDistanceSqr = starDistance * starDistance;
        starClipDistanceSqr = starClipDistance * starClipDistance;
    }

    private void CreateStars() {
        points = new ParticleSystem.Particle[starsMax];

        for (int i = 0; i < starsMax; i++)
        {
            points[i].position = Random.insideUnitSphere * starDistance + tx.position;
            points[i].startColor = new Color(1, 1, 1, 1);
            points[i].startSize = starSize;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (points == null) CreateStars();

        for (int i = 0; i < starsMax; i++)
        {
            if ((points[i].position - tx.position).sqrMagnitude > starDistanceSqr)
            {
                points[i].position = Random.insideUnitSphere.normalized * starDistance + tx.position;
            }

            if ((points[i].position - tx.position).sqrMagnitude <= starClipDistanceSqr)
            {
                float percent = (points[i].position - tx.position).sqrMagnitude / starClipDistanceSqr;
                points[i].startColor = new Color(1, 1, 1, percent);
                points[i].startSize = percent * starSize;
            }

        }
        
        particleSystem.SetParticles(points, points.Length);
    }
}
