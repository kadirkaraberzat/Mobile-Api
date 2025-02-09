const express = require('express');
const mysql = require('mysql2'); // Daha hızlı ve stabil
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require("bcrypt");


const app = express();
const PORT = 5000; // Flutter ile aynı portu kullan

//  Middleware'ler
app.use(cors({ origin: '*' })); // CORS izinleri
app.use(bodyParser.json()); // JSON veriyi okumak için

//  MySQL Bağlantısı
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'root', // Şifreni buraya yaz
    database: 'cyasar_db',
    multipleStatements: true, // Birden fazla SQL sorgusuna izin ver
});

//  MySQL Bağlantı Kontrolü
db.connect((err) => {
    if (err) {
        console.error(' MySQL bağlantı hatası:', err);
        process.exit(1); // Hata varsa çık
    }
    console.log(' MySQL bağlantısı başarılı!');
});

//  Kullanıcı Kayıt API (POST /register)
app.post('/register', async (req, res) => {
    const { name, surname, tc_no, address, email, phone, payment_info, password } = req.body;

    if (!name || !surname || !tc_no || !address || !email || !phone || !password) {
        return res.status(400).json({ error: 'Tüm alanları doldurunuz!' });
    }

    try {
        // Şifre Hashleme (bcrypt)
        const hashedPassword = await bcrypt.hash(password, 10);

        const sql = `
            INSERT INTO users (name, surname, tc_no, address, email, phone, payment_info, password) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;

        db.query(sql, [name, surname, tc_no, address, email, phone, payment_info, hashedPassword], (err, result) => {
            if (err) {
                console.error(' Veritabanı hatası:', err);
                return res.status(500).json({ error: 'Kullanıcı kaydedilemedi.' });
            }
            res.status(201).json({ message: ' Kullanıcı başarıyla kaydedildi!' });
        });
    } catch (err) {
        console.error(' Şifre işleme hatası:', err);
        res.status(500).json({ error: 'Şifre işlenirken hata oluştu.' });
    }
});

//  Kullanıcı Giriş API (POST /login)
app.post('/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email ve şifre gereklidir!' });
    }

    const sql = 'SELECT * FROM users WHERE email = ?';
    db.query(sql, [email], async (err, results) => {
        if (err) {
            console.error(' Veritabanı hatası:', err);
            return res.status(500).json({ error: 'Giriş işlemi başarısız oldu.' });
        }

        if (results.length === 0) {
            return res.status(401).json({ error: 'Böyle bir kullanıcı bulunamadı!' });
        }

        const user = results[0];

        // Şifreyi doğrula
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Şifre yanlış!' });
        }

        res.status(200).json({ message: ' Giriş başarılı!', userId: user.id });
    });
});

//  Kullanıcı Bilgilerini Getirme API (GET /user/:id)
app.get('/user/:id', (req, res) => {
    const userId = req.params.id;
    
    const sql = 'SELECT id, name, surname, email, phone, address FROM users WHERE id = ?';
    db.query(sql, [userId], (err, results) => {
        if (err) {
            console.error(' Veritabanı hatası:', err);
            return res.status(500).json({ error: 'Kullanıcı bilgileri getirilemedi.' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Kullanıcı bulunamadı!' });
        }

        res.status(200).json(results[0]);
    });
});

//  Alışveriş Kaydetme API (POST /save-purchase)
app.post('/save-purchase', (req, res) => {
    const { user_id, platform, amount } = req.body;

    if (!user_id || !platform || !amount) {
        return res.status(400).json({ error: 'Eksik alışveriş bilgisi!' });
    }

    const sql = 'INSERT INTO purchases (user_id, platform, amount) VALUES (?, ?, ?)';
    db.query(sql, [user_id, platform, amount], (err, result) => {
        if (err) {
            console.error(' Veritabanı hatası:', err);
            return res.status(500).json({ error: 'Alışveriş kaydedilemedi.' });
        }
        res.status(201).json({ message: ' Alışveriş kaydedildi!' });
    });
});

//  Kullanıcının Alışveriş Geçmişi (GET /purchases/:userId)
app.get('/purchases/:userId', (req, res) => {
    const userId = req.params.userId;

    const sql = 'SELECT * FROM purchases WHERE user_id = ?';
    db.query(sql, [userId], (err, results) => {
        if (err) {
            console.error('Veritabanı hatası:', err);
            return res.status(500).json({ error: 'Alışveriş geçmişi getirilemedi.' });
        }

        res.status(200).json(results);
    });
});

// 📌 Sunucuyu Başlat
app.listen(PORT, () => {
    console.log(` Sunucu ${PORT} portunda çalışıyor...`);
});
