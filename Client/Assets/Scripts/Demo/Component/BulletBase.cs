using UnityEngine;

public class BulletBase : ActorBase
{
    public MLabActorType targetType;

    public ActorBase owner;

    private Vector3 direction;
    private float speed;
    private float bulletDamage;
    private float lifetime = 5f; // Bullet will be destroyed after 5 seconds

    public void Initialize(Vector3 dir, float spd, float dmg)
    {
        direction = dir;
        speed = spd;
        bulletDamage = dmg;

        targetType = GameMain.Instance.GetTargeType(actorType);
    }

    private void Update()
    {
        // Move the bullet
        transform.position += direction * speed * GameMain.DeltaTime;

        // Destroy bullet after lifetime
        lifetime -= GameMain.DeltaTime;
        if (lifetime <= 0)
        {
            Destroy(gameObject);
        }
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        // Check if the hit object has a health component
        var actor = other.GetComponent<ActorBase>();
        if (actor != null && actor.actorType == targetType)
        {
            // Deal damage
            actor.TakeDamage(bulletDamage);
            actor.SetLastAttackedActor(owner);
            Destroy(gameObject);
        }
    }
}