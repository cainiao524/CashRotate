package app.cashrotate.keystore

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Holds the local database key.
 *
 * The 32-byte database key is random and never leaves the device in clear.
 * It is stored wrapped (AES-256-GCM) by a non-exportable key that lives in
 * Android Keystore, in `noBackupFilesDir` so it is never part of a backup.
 * Without this device's Keystore the wrapped key, and so the database, is
 * unreadable; restoring on another device goes through WebDAV sync instead.
 */
class DatabaseKeyStore(private val context: Context) {

    private val file: File get() = File(context.noBackupFilesDir, FILE_NAME)

    @Synchronized
    fun getOrCreate(): ByteArray {
        val f = file
        if (f.exists()) return unwrap(f.readBytes())

        val key = ByteArray(KEY_BYTES).also { SecureRandom().nextBytes(it) }
        val tmp = File(f.parentFile, "$FILE_NAME.tmp")
        tmp.writeBytes(wrap(key))
        if (!tmp.renameTo(f)) {
            tmp.delete()
            error("Could not store the database key")
        }
        return key
    }

    private fun wrappingKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (keyStore.getKey(ALIAS, null) as SecretKey?)?.let { return it }

        val spec = KeyGenParameterSpec.Builder(
            ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            .apply { init(spec) }
            .generateKey()
    }

    // Layout: [version=1][iv length][iv][ciphertext + tag]
    private fun wrap(key: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.ENCRYPT_MODE, wrappingKey())
        }
        val iv = cipher.iv
        return byteArrayOf(FORMAT_VERSION, iv.size.toByte()) + iv + cipher.doFinal(key)
    }

    private fun unwrap(blob: ByteArray): ByteArray {
        require(blob.size > 2 && blob[0] == FORMAT_VERSION) { "Unknown database key format" }
        val ivLength = blob[1].toInt()
        val iv = blob.copyOfRange(2, 2 + ivLength)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.DECRYPT_MODE, wrappingKey(), GCMParameterSpec(TAG_BITS, iv))
        }
        return cipher.doFinal(blob, 2 + ivLength, blob.size - 2 - ivLength)
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val ALIAS = "cashrotate.database.wrap"
        const val FILE_NAME = "database.key"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val TAG_BITS = 128
        const val KEY_BYTES = 32
        const val FORMAT_VERSION: Byte = 1
    }
}
