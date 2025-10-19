#!/bin/bash
# Sistemi güncelle
yum update -y

# Apache (httpd) yükle
yum install -y httpd

# Servisi başlat ve otomatik açılışa ekle
systemctl start httpd
systemctl enable httpd


# Web sayfası oluştur
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>EC2 Instance Info</title>
    <style>
      body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #f8f9fa; }
      h1 { color: #007bff; }
      p { font-size: 18px; color: #333; }
      .box { background: #fff; padding: 20px; border-radius: 10px; display: inline-block; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
    </style>
  </head>
  <body>
    <div class="box">
      <h1>EC2 Instance Information</h1>
      <p><b>Private IP:</b> $(hostname -f)</p>
    </div>
  </body>
</html>
EOF