/*----------------------------------------------------------------
 *  Description:  RC4加密
 ----------------------------------------------------------------*/
#ifndef __CST_ENCRYPT_H__
#define __CST_ENCRYPT_H__

#define RC4_KEY "ckdjfv dlkvfdlsvfkudsyo2y8743653fy438438234uerytreutyrewgitrgiytrgertgrtmxasch7463fg784fg54g5b3478g4gb8gbdidg348fbfdp2grtgrthythbv32231z32z32gbbjgjuk,m.mklmg"

// 密钥盒长度
const uint32_t    RC4_BOX_LEN = 256;

class CEncrypt
{
public:
	CEncrypt( char* key  )
	{
		s[256]={0};
		rc4_init(key);
	}
	virtual ~CEncrypt(void){};
public:

	// 加密
	void rc4_crypt( unsigned char* pData, unsigned long len)
	{
		if(NULL == pData)
		{
			assert(0);
			return;
		}

		int x = 0;
		int y = 0;
		int t = 0;

		unsigned long i = 0;
        unsigned char tmp;

		for(i=0;i<len;i++)
		{
			x=(x+1)%256;
			y=(y+s[x])%256;
            tmp=s[x];
            s[x]=s[y];
            s[y]=tmp;
			t=(s[x]+s[y])%256;
			pData[i] ^= (s[t]);
		}
	}

private:
	unsigned char s[256];
	// 加密表的初始化
	void rc4_init(char * key)
	{
        int len = strlen(key);
		if ((NULL == s) )
		{
			assert(0);
			return;
		}

		int i = 0;
		int j = 0;
		int k[256] = {0};
		unsigned char tmp = 0;

		for(i = 0; i < 256; i++)
		{
			s[i] = (uint8_t)i;
			k[i] = key[i%len];
		}

		for (i=0; i<256; i++)
		{
			j=(j+s[i]+k[i])%256;
			tmp = s[i];
			s[i] = s[j];
			s[j] = tmp;
		}
	}
};

#endif // __CST_ENCRYPT_H__

