using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MLabUtils
{
    public static bool isDebug = true;
    public static void DebugLog(string message)
   {
    #if UNITY_EDITOR
        if(isDebug)
        {
            Debug.Log(message);
        }
    #endif
    }
}
