using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BuildingBase : ActorBase
{
    [Header("Detection Settings")]
    [SerializeField] private float detectionRadius = 10f;
    [SerializeField] private float targetUpdateInterval = 0.5f;
    private float lastTargetUpdateTime;

    public override void Awake()
    {
        base.Awake();
        EnsureComponents();
        // 初始化目标更新时间
        lastTargetUpdateTime = -targetUpdateInterval; // 确保第一帧就能更新目标
    }

    private void EnsureComponents()
    {
        // 添加 Rigidbody2D
        Rigidbody2D rb = GetComponent<Rigidbody2D>();
        if (rb == null)
        {
            rb = gameObject.AddComponent<Rigidbody2D>();
        }
        rb.isKinematic = true; // 设置为运动学，不受物理影响
        rb.gravityScale = 0f;

        // 添加 Collider2D
        Collider2D collider = GetComponent<Collider2D>();
        if (collider == null)
        {
            BoxCollider2D boxCollider = gameObject.AddComponent<BoxCollider2D>();
            boxCollider.isTrigger = true;
        }
        else
        {
            collider.isTrigger = true;
        }
    }

    private void Update()
    {
        // 定期更新目标
        if (GameMain.GlobalTime >= lastTargetUpdateTime + targetUpdateInterval)
        {
            FindNearestTarget();
            lastTargetUpdateTime = GameMain.GlobalTime;
        }

        // 如果有目标，检查是否可以攻击
        if (targetTransform != null)
        {
            float distanceToTarget = Vector2.Distance(transform.position, targetTransform.position);
            CheckAndAttack(distanceToTarget);
        }

        // 检查游戏结束条件
        if (currentHealth <= 0)
        {
            GameMain.Instance.CheckGameOver();
        }
    }

    private void FindNearestTarget()
    {
        // 获取目标类型
        MLabActorType targetType = GameMain.Instance.GetTargeType(actorType);
        if (targetType == MLabActorType.None) return;

        // 获取所有可能的目标
        GameObject[] potentialTargets = GameObject.FindGameObjectsWithTag(targetType.ToString());
        float nearestDistance = float.MaxValue;
        Transform nearestTarget = null;

        foreach (GameObject target in potentialTargets)
        {
            if (target == null || !target.activeInHierarchy) continue;

            float distance = Vector2.Distance(transform.position, target.transform.position);
            if (distance < detectionRadius && distance < nearestDistance)
            {
                // 验证目标类型
                ActorBase targetActor = target.GetComponent<ActorBase>();
                if (targetActor != null && targetActor.actorType == targetType)
                {
                    nearestDistance = distance;
                    nearestTarget = target.transform;
                }
            }
        }

        targetTransform = nearestTarget;
    }

    private void OnDrawGizmosSelected()
    {
        // 显示检测范围
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position, detectionRadius);

        // 显示攻击范围
        Gizmos.color = new Color(1f, 0f, 0f, 0.3f);
        Gizmos.DrawWireSphere(transform.position, attackRange);

        // 如果有目标，显示连线
        if (targetTransform != null)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawLine(transform.position, targetTransform.position);
        }
    }
}
