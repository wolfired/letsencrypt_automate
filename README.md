# letsencrypt_automate

Auto script for obtaining [LetsEncrypt](https://letsencrypt.org/) certificates, using [Certbot](https://certbot.eff.org/) with [manual](https://certbot.eff.org/docs/using.html#manual) DNS-01 validation against [NameSilo](https://www.namesilo.com/) DNS.

# Usage

```bash
email=your@email.com ./certbot_mate.sh domain.com
```

```bash
for ((;;)); do dig -t txt _acme-challenge.{domain0.com,domain1.com} @8.8.8.8 | grep -P -o "^_acme.+"; sleep 8; done
```
