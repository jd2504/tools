﻿Module XORCrypto

    Sub Main()
        Dim input As String = Console.ReadLine()
        Dim output As String = encryptDecrypt(input)
        Console.WriteLine("Input : " & input)
        Console.WriteLine("Output : " & output)
        Dim rett As String = encryptDecrypt(output)
        Console.WriteLine("RoundAbout : " & rett)
        Console.ReadLine()
    End Sub

    ''' <summary>
    ''' Encrypts and Decrypts string via XOR Operation
    ''' </summary>
    ''' <param name="input">String to be encrypted/decrypted</param>
    ''' <returns>Encrypted/Decrypted output string</returns>
    Private Function encryptDecrypt(input As String) As String
        Dim key As Char() = {"B"c, "r"c, "C"c}
        'Any chars will work, in an array of any size
        Dim output As Char() = New Char(input.Length - 1) {}
        For i As Integer = 0 To input.Length - 1
            output(i) = ChrW(AscW(input(i)) Xor AscW(key(i Mod key.Length)))
            'ChrW(CharCode As Integer) As Char (Unicode) : Returns the character associated with the specified character code
            'AscW([String] As Char) As Integer (Unicode) : Returns an integer value representing the character code corresponding to a character
        Next
        Return New String(output)
    End Function

End Module
