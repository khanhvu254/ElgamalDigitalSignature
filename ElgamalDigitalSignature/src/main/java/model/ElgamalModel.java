package model;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Random;

public class ElgamalModel {
    
    // Hàm băm SHA-256
    public BigInteger getHash(String text) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] digest = md.digest(text.getBytes("UTF-8"));
        return new BigInteger(1, digest);
    }

    // Sinh số K ngẫu nhiên
    public BigInteger generateK(BigInteger p) {
        BigInteger pMinus1 = p.subtract(BigInteger.ONE);
        Random rng = new SecureRandom();
        BigInteger k;
        do {
            k = new BigInteger(p.bitLength(), rng).mod(pMinus1);
        } while (!k.gcd(pMinus1).equals(BigInteger.ONE) || k.compareTo(BigInteger.ONE) <= 0);
        return k;
    }
    
    // Kiểm tra alpha có phải căn nguyên modulo p không
    public boolean isPrimitiveRoot(BigInteger alpha, BigInteger p) {
        BigInteger phi = p.subtract(BigInteger.ONE);
        BigInteger n = phi;

        for (BigInteger i = BigInteger.TWO;
             i.multiply(i).compareTo(n) <= 0;
             i = i.add(BigInteger.ONE)) {

            if (n.mod(i).equals(BigInteger.ZERO)) {

                if (alpha.modPow(phi.divide(i), p).equals(BigInteger.ONE)) {
                    return false;
                }

                while (n.mod(i).equals(BigInteger.ZERO)) {
                    n = n.divide(i);
                }
            }
        }

        if (n.compareTo(BigInteger.ONE) > 0) {
            if (alpha.modPow(phi.divide(n), p).equals(BigInteger.ONE)) {
                return false;
            }
        }

        return true;
    }

    // Hàm sinh khóa ngẫu nhiên 
    public BigInteger[] generateKeys(int bitLength) {
        SecureRandom rng = new SecureRandom();

        BigInteger q, p;
        do {
            q = BigInteger.probablePrime(bitLength - 1, rng);
            p = q.multiply(BigInteger.TWO).add(BigInteger.ONE);
        } while (!p.isProbablePrime(50));

        BigInteger alpha;
        do {
            alpha = new BigInteger(bitLength - 2, rng).add(BigInteger.TWO);
        } while (
            alpha.modPow(BigInteger.TWO, p).equals(BigInteger.ONE) ||
            alpha.modPow(q, p).equals(BigInteger.ONE)
        );

        BigInteger x = new BigInteger(bitLength - 2, rng).add(BigInteger.ONE);
        BigInteger y = alpha.modPow(x, p);

        return new BigInteger[]{p, alpha, x, y};
    }


    // Ký chữ ký
    public String[] sign(String message, BigInteger p, BigInteger alpha, BigInteger x) throws Exception {
        BigInteger m = getHash(message);
        BigInteger k = generateK(p);
        
        // r = alpha^k mod p
        BigInteger r = alpha.modPow(k, p);
        
        // s = k^-1 * (m - x*r) mod (p-1)
        BigInteger pMinus1 = p.subtract(BigInteger.ONE);
        BigInteger kInv = k.modInverse(pMinus1);
        BigInteger temp = m.subtract(x.multiply(r));
        BigInteger s = temp.multiply(kInv).mod(pMinus1);
        
        return new String[]{r.toString(), s.toString()};
    }

    // Xác minh 
    public boolean verify(String message, String rStr, String sStr, BigInteger p, BigInteger alpha, BigInteger y) {
        try {
            BigInteger r = new BigInteger(rStr);
            BigInteger s = new BigInteger(sStr);
            
            if (r.compareTo(BigInteger.ZERO) <= 0 || r.compareTo(p) >= 0) return false;
            
            BigInteger m = getHash(message);
            
            // v1 = (y^r * r^s) mod p
            BigInteger v1 = y.modPow(r, p).multiply(r.modPow(s, p)).mod(p);
            // v2 = alpha^m mod p
            BigInteger v2 = alpha.modPow(m, p);
            
            return v1.equals(v2);
        } catch (Exception e) {
            return false;
        }
    }
    
    public String validateInputKeys(BigInteger p, BigInteger alpha, BigInteger x) {

        if (p.compareTo(BigInteger.TWO) <= 0) {
            return "p phải lớn hơn 2";
        }

        if (!p.isProbablePrime(50)) {
            return "p phải là số nguyên tố";
        }

        if (alpha.compareTo(BigInteger.ONE) <= 0 || alpha.compareTo(p) >= 0) {
            return "alpha phải thỏa mãn 1 < alpha < p";
        }

        if (!isPrimitiveRoot(alpha, p)) {
            return "alpha phải là căn nguyên modulo p";
        }

        if (x.compareTo(BigInteger.ONE) < 0 || x.compareTo(p.subtract(BigInteger.ONE)) >= 0) {
            return "Khóa bí mật x phải thỏa mãn 1 ≤ x ≤ p − 2";
        }

        return null;
    }

}