def encryptDecrypt(string)
    key = ['B', 'r', 'C']
    result = ""
    codepoints = string.each_codepoint.to_a
    codepoints.each_index do |i|
        result += (codepoints[i] ^ key[i % key.size].ord).chr
    end
    result
end

encrypted = encryptDecrypt("kylewbanks.com")
puts "Encrypted: #{encrypted}"

decrypted = encryptDecrypt(encrypted)
puts "Decrypted: #{decrypted}"
