using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Health : MonoBehaviour
{
    public float healthValue = 100.0f;
    public HealthBar healthBar;

    private void Awake()
    {
        if(healthBar != null)
        {
            healthBar.SetMaxHealth(healthValue);
            healthBar.UpdateHealth(healthValue);
        }
    }
    public void TakeDamage(float damage)
    {
        healthValue = Mathf.Max(healthValue - damage, 0.0f);
        if (healthBar != null)
        { 
            healthBar.UpdateHealth(healthValue);
        }
    }

    public void SetHealth(float health)
    {
        healthValue = health;
        if (healthBar != null)
        {
            healthBar.UpdateHealth(healthValue);
        }
    }
}
