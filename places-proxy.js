const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const GOOGLE_API_KEY = 'AIzaSyDg6aJ0F5soP4Y9M4ZGAQ5RJAtFB-PfMa0';

app.use(cors());

app.get('/places', async (req, res) => {
  const { input, sessiontoken } = req.query;
  if (!input || !sessiontoken) {
    return res.status(400).json({ error: 'Missing input or sessiontoken' });
  }
  const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&language=uk&components=country:UA&sessiontoken=${sessiontoken}&key=${GOOGLE_API_KEY}`;
  try {
    const response = await fetch(url);
    const data = await response.json();
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.toString() });
  }
});

app.listen(PORT, () => {
  console.log(`Proxy server running on http://localhost:${PORT}`);
}); 