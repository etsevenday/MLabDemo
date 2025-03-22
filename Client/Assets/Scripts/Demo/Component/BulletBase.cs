using UnityEngine;

public class BulletBase : MonoBehaviour
{
    public MLabActorType actorType;
    public MLabActorType targetType;

    private WeaponBase Weapon;
    private GameObject target;
    private float speed;
    private float bulletDamage;
    private float lifetime = 5f; // Bullet will be destroyed after 5 seconds

    public void Initialize(GameObject target, float spd, float dmg, MLabActorType actorType, WeaponBase weapon)
    {
        this.target = target;
        speed = spd;
        bulletDamage = dmg;
        this.actorType = actorType;
        this.Weapon = weapon;
        targetType = GameMain.Instance.GetTargeType(actorType);
    }

    private void Update()
    {
        if (target == null || target.transform == null)
        {
            Destroy(gameObject);
            return;
        }
        // Move the bullet
        Vector3 direction = target.transform.position - transform.position;
        transform.position += direction.normalized * speed * GameMain.DeltaTime;

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
            //DamageCalculator.Instance.CalculateDamage(this, target.GetComponent<ActorBase>());
            actor.TakeDamage(bulletDamage);
            actor.SetLastAttackedActor(GetComponentInParent<WeaponBase>()?.GetOwner());
            Weapon.OnBulletHit(this);
            Destroy(gameObject);
        }
    }
}