using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RayMarchCollider : MonoBehaviour
{

    public int nrPoints = 18;
    public float colliderOffset = 1.2f;
    public GameObject colPlane;
    public GameObject DistanceSphere;
    private DistanceFunctions df;
    private RaymarchPostProcess cam;
    private float colRadius;
    // private float colHeight;
    private Vector3 ro;
    Vector3[] colliders;
    private Rigidbody rb;

    // Start is called before the first frame update
    void Start()
    {   
        cam = GameObject.FindObjectOfType<RaymarchPostProcess>();
        df = GetComponent<DistanceFunctions>();
        colRadius = GetComponent<SphereCollider>().radius;
        colliders = PointsOnSphere(nrPoints, colRadius * colliderOffset);
        rb = GetComponent<Rigidbody>();
        // colRadius = GetComponent<CapsuleCollider>().radius;
        // colHeight = GetComponent<CapsuleCollider>().height;
    }

    // Update is called once per frame
    void Update()
    {
        if (IsClose())
        {
            Raymarching(colliders);
        }
        
    }

    // the distancefunction from the player
    public float DistanceField(Vector3 p)
    {
        float dist = Camera.main.farClipPlane + 1;
        // float dist = 0f;

        // check modulor
        if (cam.isModulor.value)
        {
            p.x = df.mod(p.x, cam.modInterval.value.x);
            p.y = df.mod(p.y, cam.modInterval.value.y);
            p.z = df.mod(p.z, cam.modInterval.value.z);
        }
        // Mandelbox
        if (cam.isMandelbox.value)
        {
            dist = df.mandelboxSDF((p * cam.mandelbox.value.w) - new Vector3(cam.mandelbox.value.x, cam.mandelbox.value.y, cam.mandelbox.value.z), cam.scaleBox.value, cam.iterationsBox.value, cam.fixedRadius2.value, cam.minRadius2.value, cam.foldingLimit.value, cam.boxBreathe.value, cam.myTime);
        }

        return dist;
    }

    void Raymarching(Vector3[] rd)
    {
        ro = transform.position;
        int nrHits = 0;
        
        for (int i = 0; i < rd.Length; i++)
        {
            Vector3 p = ro + Vector3.Normalize(rd[i]) * colRadius;
            // check hit
            float d = DistanceField(p);

            if (Mathf.Abs(d) <= cam.minDistance) // hit
            {
                // Debug.Log("hit" + i);
                nrHits++;
                // collision
                SetColPlane(rd[i]);
            }

        }
    }

    private void SetColPlane(Vector3 hitPoint)
    {
        Instantiate(colPlane, hitPoint + transform.position, Quaternion.identity);
    }

    // checks if the player is close
    bool IsClose()
    {
        float d = DistanceField(transform.position);
        // Debug.Log(d);
        // DistanceSphere.transform.localScale = Vector3.one * d * 2; // debug distance sphere
        return d - (colRadius * colliderOffset) < cam.minDistance;
    }

        //creates a fixed number of points on a sphere
    Vector3[] PointsOnSphere(int n, float b)
    {
        List<Vector3> upts = new List<Vector3>();
        float inc = Mathf.PI * (3 - Mathf.Sqrt(5));
        float off = 2.0f / n;
        float x = 0;
        float y = 0;
        float z = 0;
        float r = 0;
        float phi = 0;

        for (var k = 0; k < n; k++)
        {
            y = k * off - 1 + (off / 2);
            r = Mathf.Sqrt(1 - y * y);
            phi = k * inc;
            x = Mathf.Cos(phi) * r;
            z = Mathf.Sin(phi) * r;

            upts.Add(new Vector3(x, y, z) * b);
        }
        Vector3[] pts = upts.ToArray();
        return pts;
    }
}
