#!/bin/bash

# Proje adı
PROJECT_NAME="kinoo"

# GitHub URL
GITHUB_URL="https://github.com/<your-username>/$PROJECT_NAME.git"

# Klasör oluşturuluyor
mkdir -p src/components src/utils public/images
cd $PROJECT_NAME

# Git deposu başlatılıyor
git init

# Ana dosya yapısını oluşturuyoruz
touch public/images/default.jpg

# src/utils klasöründe gerekli dosyalar
cat <<EOL > src/utils/getPoster.js
const API_KEY = '9fbeefd9c72e02a5779273e36fd769a5';
const BASE_URL = 'https://api.themoviedb.org/3/search/tv';
const IMAGE_BASE = 'https://image.tmdb.org/t/p/w500';

const cache = {};

export async function getPoster(query) {
  if (cache[query]) return cache[query];

  try {
    const res = await fetch(\`\${BASE_URL}?api_key=\${API_KEY}&query=\${encodeURIComponent(query)}\`);
    const data = await res.json();

    if (data?.results?.[0]?.poster_path) {
      const posterUrl = IMAGE_BASE + data.results[0].poster_path;
      cache[query] = posterUrl;
      return posterUrl;
    }
  } catch (err) {
    console.error("Poster çekilemedi:", err);
  }

  return null; // Yoksa boş dön
}
EOL

# src/utils/parseM3U.js
cat <<EOL > src/utils/parseM3U.js
export function parseM3U(m3uContent) {
  const lines = m3uContent.split('\\n');
  const groups = {};
  let current = {};

  for (let line of lines) {
    line = line.trim();
    if (line.startsWith('#EXTINF')) {
      const nameMatch = line.match(/,(.*)\$/);
      const groupMatch = line.match(/group-title="([^"]+)"/);
      const logoMatch = line.match(/tvg-logo="([^"]+)"/);

      const fullName = nameMatch ? nameMatch[1].trim() : 'Bilinmeyen';
      const seasonEpisodeMatch = fullName.match(/(\\d+\\. Sezon \\d+\\. Bölüm)/);

      current.title = fullName;
      current.name = seasonEpisodeMatch ? seasonEpisodeMatch[1] : fullName;
      current.group = groupMatch ? groupMatch[1].trim() : 'Diğer';
      current.logo = logoMatch ? logoMatch[1] : null;
    } else if (line.startsWith('http')) {
      const finalUrl = line.includes('diziyou7.com') ? line.replace('/play.m3u8', '/1080p.m3u8') : line;
      current.url = convertVidmodyLink(finalUrl);
      if (!groups[current.group]) groups[current.group] = [];
      groups[current.group].push({ ...current });
      current = {};
    }
  }

  return groups;
}

function convertVidmodyLink(url) {
  const match = url.match(/vidmody\\.com\\/vs\\/(tt\\d+)/);
  if (match) {
    const imdbId = match[1];
    return \`https://vidmody.com/mm/\${imdbId}/main/index.m3u8\`;
  }
  return url;
}
EOL

# src/components dosyasındaki bileşenler
cat <<EOL > src/components/ChannelList.jsx
import { useEffect, useState, useRef } from 'react';
import { parseM3U } from '../utils/parseM3U';

export default function ChannelList({ onSelect }) {
  const [channels, setChannels] = useState([]);
  const [focusedIndex, setFocusedIndex] = useState(0);
  const containerRef = useRef(null);

  useEffect(() => {
    const urls = [
      "https://raw.githubusercontent.com/UzunMuhalefet/Legal-IPTV/main/lists/video/sources/www-dmax-com-tr/all.m3u",
      "https://raw.githubusercontent.com/UzunMuhalefet/Legal-IPTV/main/lists/video/sources/www-tlctv-com-tr/all.m3u",
      "https://raw.githubusercontent.com/sarapcanagii/Pitipitii/refs/heads/master/NeonSpor/NeonSpor.m3u8",
      "https://raw.githubusercontent.com/GitLatte/patr0n/site/lists/power-sinema.m3u",
      "https://raw.githubusercontent.com/GitLatte/patr0n/site/lists/power-yabanci-dizi.m3u",
      "https://raw.githubusercontent.com/UzunMuhalefet/Legal-IPTV/main/lists/video/sources/www-cartoonnetwork-com-tr/videolar.m3u"
    ];

    const fetchAll = async () => {
      const results = await Promise.all(urls.map(url =>
        fetch(url).then(r => r.text()).then(parseM3U)
      ));
      setChannels(results.flat());
    };

    fetchAll();
  }, []);

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === "ArrowDown") {
        setFocusedIndex((prev) => Math.min(prev + 1, channels.length - 1));
      } else if (e.key === "ArrowUp") {
        setFocusedIndex((prev) => Math.max(prev - 1, 0));
      } else if (e.key === "Enter") {
        if (channels[focusedIndex]) {
          onSelect(channels[focusedIndex]);
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [channels, focusedIndex, onSelect]);

  useEffect(() => {
    const item = containerRef.current?.querySelector(\`[data-index="\${focusedIndex}"]\`);
    if (item) item.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }, [focusedIndex]);

  return (
    <div
      ref={containerRef}
      style={{ maxHeight: '100vh', overflowY: 'auto', padding: '10px' }}
    >
      {channels.map((channel, index) => (
        <div
          key={index}
          data-index={index}
          style={{
            padding: '12px 16px',
            marginBottom: '10px',
            background: focusedIndex === index ? '#555' : '#1a1a1a',
            color: focusedIndex === index ? '#00ffff' : '#ffffff',
            borderRadius: '12px',
            fontSize: '1.1rem',
            transition: 'background 0.2s',
            boxShadow: focusedIndex === index ? '0 0 10px #00ffff' : 'none'
          }}
        >
          {channel.name}
        </div>
      ))}
    </div>
  );
}
EOL

# Artık GitHub'a dosyaları ekleyebiliriz
git add .
git commit -m "İlk proje dosyaları"
git push -u origin main

echo "Proje başarıyla GitHub'a yüklendi!"
