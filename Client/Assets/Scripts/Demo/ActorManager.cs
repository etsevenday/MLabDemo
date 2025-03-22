using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Sirenix.OdinInspector;
using Unity.VisualScripting;
using UnityEngine;

public class ActorManager : MonoBehaviour
{
    public static ActorManager Instance
    {
        get
        {
            if(instance == null)
            {
                instance = FindObjectOfType<ActorManager>();
            }
            return instance;
        }
    }
    private static ActorManager instance;

    [LabelText("红方棋子")]
    public GameObject actorRed;
    [LabelText("蓝方棋子")]
    public GameObject actorBlue;

    [Header("Spawn Area Settings")]
    [LabelText("生成区域宽度")]
    [SerializeField] private float spawnAreaWidth = 10f;
    [LabelText("生成区域高度")]
    [SerializeField] private float spawnAreaHeight = 10f;
    [LabelText("生成区域中心偏移")]
    [SerializeField] private Vector2 spawnAreaOffset = Vector2.zero;

    private List<GameObject> redActorList = new List<GameObject>();
    private List<GameObject> blueActorList = new List<GameObject>();
    
    private int redSpawnCount = 0; 
    private int blueSpawnCount = 0; 

    void Awake()
    {
        redActorList = GameObject.FindGameObjectsWithTag("PlayerA").ToList();
        blueActorList = GameObject.FindGameObjectsWithTag("PlayerB").ToList();
    }

    // Update is called once per frame
    void Update()
    {
        if(redSpawnCount > 0)
        {
            for(int i = 0; i < redSpawnCount; i++)
            {
                SpawnActor(MLabActorType.PlayerA);
            }
            redSpawnCount = 0;
        }

        if(blueSpawnCount > 0)
        {
            for(int i = 0; i < blueSpawnCount; i++)
            {
                SpawnActor(MLabActorType.PlayerB);
            }
            blueSpawnCount = 0;
        }
    }

    public void SpawnActor(MLabActorType actorType)
    {
        GameObject actor = actorType == MLabActorType.PlayerA ? actorRed : actorBlue;
        
        // Calculate random position within spawn area
        float randomX = Random.Range(-spawnAreaWidth/2, spawnAreaWidth/2) + spawnAreaOffset.x + transform.position.x;
        float randomY = Random.Range(-spawnAreaHeight/2, spawnAreaHeight/2) + spawnAreaOffset.y + transform.position.y;
        Vector3 spawnPosition = new Vector3(randomX, randomY, transform.position.z);
        
        Instantiate(actor, spawnPosition, Quaternion.identity);
    }

    public void RemoveActor(GameObject actor, MLabActorType actorType)
    {
        if(actorType == MLabActorType.PlayerA)
        {
            GameMain.Instance.blueSpawn.GetExp(actor.GetComponent<ActorBase>().expValue);
            redActorList.Remove(actor);
            blueSpawnCount += 2;
        }
        else
        {
            GameMain.Instance.redSpawn.GetExp(actor.GetComponent<ActorBase>().expValue);
            blueActorList.Remove(actor);
            redSpawnCount += 2;
        }
        Destroy(actor);
    }

#if UNITY_EDITOR
    private void OnDrawGizmosSelected()
    {
        // Draw spawn area in editor
        Gizmos.color = new Color(0, 1, 0, 0.3f);
        Vector3 center = transform.position + new Vector3(spawnAreaOffset.x, spawnAreaOffset.y, 0);
        Gizmos.DrawCube(center, new Vector3(spawnAreaWidth, spawnAreaHeight, 0.1f));
        
        // Draw outline
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(center, new Vector3(spawnAreaWidth, spawnAreaHeight, 0.1f));
    }
#endif
}
