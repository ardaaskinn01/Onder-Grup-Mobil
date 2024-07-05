const express = require('express');
const mysql = require('mysql2');
const Minio = require('minio');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const jwtSecret = process.env.JWT_SECRET;
const multer = require('multer');
require('dotenv').config();

const app = express();
const port = 3000;
const host = '0.0.0.0'; // Tüm IP adreslerinde dinlemek için

// MySQL bağlantı ayarları
const dbConfig = {
  host: 'mysql-container', // Docker Compose'da belirtilen host
  user: process.env.DATABASE_USER || 'root',     // Docker Compose'da belirtilen kullanıcı
  password: process.env.DATABASE_PASSWORD || 'ondergrup450', // Docker Compose'da belirtilen şifre
  database: process.env.DATABASE_NAME || 'mydb', // Docker Compose'da belirtilen veritabanı adı
  port: process.env.DATABASE_PORT || '3306',     // Docker Compose'da belirtilen port (3308)
};

// MinIO istemcisini başlatma
const minioClient = new Minio.Client({
  endPoint: 'localhost',
  port: 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY,
  secretKey: process.env.MINIO_SECRET_KEY,
});

const dbConnection = mysql.createConnection(dbConfig);

dbConnection.connect(err => {
  if (err) {
    console.error('MySQL veritabanına bağlantı başarısız:', err);
    throw err;
  }
  console.log('MySQL veritabanına başarıyla bağlanıldı.');
});

// Body parser middleware'i ekleyin
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Dosya yükleme endpoint'i
const upload = multer({ dest: 'uploads/' });

app.get('/', (req, res) => {
  res.send('Hello');
});

// Dosya yükleme
app.post('/uploadFile', upload.single('file'), (req, res) => {
  const { file } = req;
  const bucketName = 'ondergrup';

  minioClient.fPutObject(bucketName, file.originalname, file.path, (err, etag) => {
    if (err) {
      console.error('Error uploading file:', err);
      return res.status(500).send({ error: 'Failed to upload file.' });
    }
    res.status(200).send({ message: 'File uploaded successfully', etag });
  });
});

// Dosya indirme
app.get('/downloadFile', (req, res) => {
  const { filename } = req.query;
  const bucketName = 'ondergrup';

  minioClient.getObject(bucketName, filename, (err, dataStream) => {
    if (err) {
      console.error('Error downloading file:', err);
      return res.status(500).send({ error: 'Failed to download file.' });
    }

    dataStream.pipe(res);
  });
});

app.listen(port, host, () => {
  console.log(`Node app şu adreste dinleniyor: http://85.95.231.92:${port}`);
});

function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.status(401).send({ error: 'Token missing' });

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).send({ error: 'Invalid token' });
    req.user = user;
    next();
  });
}

// Kullanıcı kaydı
app.post('/registerUser', async (req, res) => {
  const { name, email, username, password, role } = req.body;

  if (!name || !email || !username || !password) {
    return res.status(400).send({ error: 'All fields are required.' });
  }

  try {
    // Kullanıcıyı MySQL veritabanına kaydet
    const hashedPassword = await bcrypt.hash(password, 10);
    const query = 'INSERT INTO Users (name, email, username, password, role) VALUES (?, ?, ?, ?, ?)';
    dbConnection.query(query, [name, email, username, hashedPassword, role], (err, result) => {
      if (err) {
        console.error('Error registering user:', err);
        return res.status(500).send({ error: 'Failed to register user. Please try again later.' });
      }
      res.status(201).send({ message: 'User registered successfully', userId: result.insertId });
    });
  } catch (error) {
    console.error('Error registering user:', error);
    return res.status(500).send({ error: 'Failed to register user. Please try again later.' });
  }
});

// POST endpoint - Kullanıcı oturum açma
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).se,nd({ error: 'Email and password are required.' });
  }

  const query = 'SELECT * FROM Users WHERE email = ?';
  dbConnection.query(query, [email], async (err, results) => {
    if (err) {
      console.error('Error logging in user:', err);
      return res.status(500).send({ error: 'Failed to login. Please try again later.' });
    }

    if (results.length === 0) {
      return res.status(401).send({ error: 'Invalid email or password.' });
    }

    const user = results[0];
    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return res.status(401).send({ error: 'Invalid email or password.' });
    }

    const token = jwt.sign({ uid: user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).send({ token });
  });
});

app.post('/changePassword', authenticateToken, async (req, res) => {
  const { newPassword } = req.body;
  const userId = req.user.uid; // `authenticateToken` middleware'den gelen kullanıcı id'si

  if (!newPassword) {
    return res.status(400).send({ error: 'Missing newPassword' });
  }

  try {
    // Yeni parolayı hash'leyin
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // MySQL sorgusu ile parola güncelleme
    const query = 'UPDATE Users SET password = ? WHERE id = ?';
    dbConnection.query(query, [hashedPassword, userId], (err, results) => {
      if (err) {
        console.error('Error updating password:', err);
        return res.status(500).send({ error: 'Failed to update password' });
      }

      res.status(200).send({ message: 'Password changed successfully' });
    });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).send({ error: 'Failed to change password' });
  }
});

// POST endpoint - Kullanıcı profili güncelleme
app.post('/updateUserProfile', authenticateToken, (req, res) => {
  const { name, username } = req.body;
  const uid = req.user.uid; // authenticateToken middleware ile gelen kullanıcı ID'si

  const query = 'UPDATE Users SET name = ?, username = ? WHERE id = ?';
  dbConnection.query(query, [name, username, uid], (err, results) => {
    if (err) {
      console.error('Error updating user profile:', err);
      return res.status(500).send({ error: 'Failed to update user profile.' });
    }
    res.status(200).send({ message: 'Profile updated successfully' });
  });
});

// GET endpoint - Kullanıcı profili getirme
app.get('/getUserProfile', authenticateToken, (req, res) => {
  const uid = req.user.uid; // authenticateToken middleware ile gelen kullanıcı ID'si

  // Kullanıcı bilgilerini sorgula
  const query = 'SELECT * FROM Users WHERE id = ?';
  dbConnection.query(query, [uid], (err, results) => {
    if (err) {
      console.error('Error fetching user profile:', err);
      return res.status(500).send({ error: 'Failed to fetch user profile.' });
    }
    if (results.length === 0) {
      return res.status(404).send({ error: 'User not found.' });
    }
    // Kullanıcı profilini döndür
    res.status(200).send(results[0]);
  });
});

// Makine ekleme endpoint'i
app.post('/addMachine', async (req, res) => {
  const { machineName, machineID, machineType, ownerUser } = req.body;

  if (!machineName || !machineID || !machineType || !ownerUser) {
    return res.status(400).send({ error: 'All fields are required.' });
  }

  const query = 'INSERT INTO machines (machineName, machineID, machineType, ownerUser) VALUES (?, ?, ?, ?)';
  dbConnection.query(query, [machineName, machineID, machineType, ownerUser], (err, result) => {
    if (err) {
      console.error('Error adding machine:', err);
      return res.status(500).send({ error: 'Failed to add machine. Please try again later.' });
    }
    res.status(201).send({ message: 'Machine added successfully', machineId: result.insertId });
  });
});

// Makine listesi alma endpoint'i
app.get('/getMachines', (req, res) => {
  const query = 'SELECT * FROM machines';
  dbConnection.query(query, (err, results) => {
    if (err) {
      console.error('Error getting machines:', err);
      return res.status(500).send({ error: 'Failed to get machines. Please try again later.' });
    }
    res.status(200).send(results);
  });
});

// Makine detayları alma endpoint'i
app.get('/getMachineDetails', async (req, res) => {
  const { machineID } = req.query;

  if (!machineID) {
    return res.status(400).json({ error: 'Missing machineName parameter' });
  }

  const query = 'SELECT * FROM machines WHERE machineID = ?';
  dbConnection.query(query, [machineID], (err, results) => {
    if (err) {
      console.error('Error getting machine details:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Machine not found' });
    }

    const machineData = results[0];
    const sortedMachineData = {}; // Assuming you want sorted data, adjust if necessary
    const keys = Object.keys(machineData).sort(); // Sort keys alphabetically

    keys.forEach(key => {
      sortedMachineData[key] = machineData[key];
    });

    res.status(200).json(sortedMachineData);
  });
});

// Makine silme endpoint'i
app.delete('/deleteMachine', async (req, res) => {
  const { machineName } = req.query;

  if (!machineName) {
    return res.status(400).json({ error: 'Missing machineName parameter' });
  }

  const query = 'DELETE FROM machines WHERE machineName = ?';
  dbConnection.query(query, [machineName], async (err, results) => {
    if (err) {
      console.error('Error deleting machine:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    // Assuming you also have subcollections in MySQL and need to delete them
    // Handle deletion of subcollections as needed

    res.status(200).json({ message: 'Machine and its subcollections deleted successfully' });
  });
});

// Servis ve bakım verilerini alma endpoint'i
app.get('/getMaintenanceData', async (req, res) => {
  const { machineID, maintenanceId } = req.query;

  if (!machineID || !maintenanceId) {
    return res.status(400).json({ error: 'Missing machineID or maintenanceId parameter' });
  }

  const query = 'SELECT * FROM maintenances WHERE machineID = ? AND maintenanceId = ?';
  dbConnection.query(query, [machineID, maintenanceId], (err, results) => {
    if (err) {
      console.error('Error getting maintenance data:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Maintenance not found' });
    }

    res.status(200).json(results[0]);
  });
});

// Servis ve bakım ekleme endpoint'i
app.post('/addMaintenance', async (req, res) => {
  const { machineID, maintenanceId, maintenanceDate, maintenanceStatuses, notes } = req.body;

  if (!machineID || !maintenanceId || !maintenanceDate) {
    return res.status(400).json({ error: 'All fields are required.' });
  }

  const query = `
    INSERT INTO maintenances (machineID, maintenanceId, maintenanceDate, kontroller, notes)
    VALUES (?, ?, ?, ?, ?)
  `;

  dbConnection.query(
    query,
    [
      machineID,
      maintenanceId,
      maintenanceDate,
      JSON.stringify(maintenanceStatuses),
      JSON.stringify(notes)
    ],
    (err, result) => {
      if (err) {
        console.error('Error adding maintenance:', err);
        return res.status(500).json({ error: 'Internal Server Error' });
      }
      res.status(200).json({ message: 'Maintenance added successfully', maintenanceId: result.insertId });
    }
  );
});

// Servis ve bakım kayıtlarını alma endpoint'i
app.get('/getMaintenanceRecords', async (req, res) => {
  const { machineID } = req.query;

  if (!machineID) {
    return res.status(400).json({ error: 'Missing machineID parameter' });
  }

  const query = 'SELECT * FROM maintenances WHERE machineID = ?';
  dbConnection.query(query, [machineID], (err, results) => {
    if (err) {
      console.error('Error getting maintenance records:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    res.status(200).json(results);
  });
});

// Kullanıcı rolü alma endpoint'i
app.get('/getRole', async (req, res) => {
  const { uid } = req.query;

  if (!uid) {
    return res.status(400).json({ error: 'Missing UID parameter' });
  }

  const query = 'SELECT role FROM Users WHERE email = ?';
  dbConnection.query(query, [uid], async (err, results) => {
    if (err) {
      console.error('Error getting user role:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const role = results[0].role;
    res.status(200).json({ role });
  });
});

// Hata kayıtlarını alma endpoint'i
app.get('/getErrorRecords', async (req, res) => {
  const { machineName } = req.query;

  if (!machineName) {
    return res.status(400).json({ error: 'Missing machineName parameter' });
  }

  const query = 'SELECT * FROM errors WHERE machineName = ?';
  dbConnection.query(query, [machineName], (err, results) => {
    if (err) {
      console.error('Error getting error records:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    res.status(200).json(results);
  });
});