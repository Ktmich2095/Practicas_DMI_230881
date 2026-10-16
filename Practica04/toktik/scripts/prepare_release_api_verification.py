"""Create a local TLS fixture for REAL Android/API verification, not for shipping."""
import datetime
import base64
import json
from pathlib import Path
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID

ROOT=Path(__file__).resolve().parents[1]
target=ROOT/'build/api-verification'
target.mkdir(parents=True,exist_ok=True)
if (target/'cert.pem').exists() and (target/'key.pem').exists():
    cert=x509.load_pem_x509_certificate((target/'cert.pem').read_bytes())
    key=serialization.load_pem_private_key((target/'key.pem').read_bytes(),password=None)
else:
    key=rsa.generate_private_key(public_exponent=65537,key_size=2048)
    name=x509.Name([x509.NameAttribute(NameOID.COMMON_NAME,'localhost')])
    now=datetime.datetime.now(datetime.timezone.utc)
    cert=(x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
          .serial_number(x509.random_serial_number()).not_valid_before(now-datetime.timedelta(minutes=5))
          .not_valid_after(now+datetime.timedelta(days=1)).add_extension(x509.SubjectAlternativeName([x509.DNSName('localhost')]),critical=False)
          .sign(key,hashes.SHA256()))
pem=cert.public_bytes(serialization.Encoding.PEM).decode()
(target/'cert.pem').write_text(pem,encoding='ascii')
(target/'key.pem').write_bytes(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
(target/'public-test-defines.json').write_text(json.dumps({'TOKTIK_API_BASE_URL':'https://localhost:8765','TEST_GATEWAY_CERT_DER':base64.urlsafe_b64encode(cert.public_bytes(serialization.Encoding.DER)).decode()}),encoding='utf-8')
print('Local TLS certificate and non-secret test defines created under build/api-verification/.')
