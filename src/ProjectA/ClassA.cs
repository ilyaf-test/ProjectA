﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ProjectA
{
    public class ClassA
    {
        public int MyPropertyA { get; set; }
        // original pulldssd
        public ClassA(int myPropertyA)
        {
            this.MyPropertyA = myPropertyA;
        }
    }
}
