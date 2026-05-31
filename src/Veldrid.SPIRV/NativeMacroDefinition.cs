using System;
using System.Runtime.InteropServices;
using System.Text;

namespace Veldrid.SPIRV
{
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal unsafe struct NativeMacroDefinition
    {
		private const int MAX_BUFFER_SIZE = 128;
		
        public uint NameLength;
        public fixed byte Name[MAX_BUFFER_SIZE];
        public uint ValueLength;
        public fixed byte Value[MAX_BUFFER_SIZE];

        public NativeMacroDefinition(MacroDefinition macroDefinition)
        {
            if (string.IsNullOrEmpty(macroDefinition.Name))
            {
                throw new SpirvCompilationException($"MacroDefinition Name must be non-null.");
            }
            if (macroDefinition.Name.Length > MAX_BUFFER_SIZE)
            {
                throw new SpirvCompilationException($"Macro names must be less than or equal to {MAX_BUFFER_SIZE} characters.");
            }

            fixed (char* nameU16Ptr = macroDefinition.Name)
            fixed (byte* namePtr = Name)
            {
                NameLength = (uint)Encoding.ASCII.GetBytes(nameU16Ptr, macroDefinition.Name.Length, namePtr, MAX_BUFFER_SIZE);
            }

            if (!string.IsNullOrEmpty(macroDefinition.Value))
            {
                if (macroDefinition.Value.Length > MAX_BUFFER_SIZE)
                {
                    throw new SpirvCompilationException($"Macro values must be less than or equal to {MAX_BUFFER_SIZE} characters.");
                }

                fixed (char* valueU16 = macroDefinition.Value)
                fixed (byte* valuePtr = Value)
                {
                    ValueLength = (uint)Encoding.ASCII.GetBytes(valueU16, macroDefinition.Value.Length, valuePtr, MAX_BUFFER_SIZE);
                }
            }
            else
            {
                ValueLength = 0;
            }
        }
    }
}