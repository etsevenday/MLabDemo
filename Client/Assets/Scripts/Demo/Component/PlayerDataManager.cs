using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerDataManager : MonoBehaviour
{
    public int money = 0;
    // Start is called before the first frame update
    public void AddMoney(int amount)
    {
        money += amount;
    }

    // Update is called once per frame
    public void UseMoney(int amount)
    {
        money -= amount;
    }
}
