-- ===========================================
-- MAPAS BONITOS - Seed Themes
-- ===========================================
-- Run after schema.sql to populate themes table
-- mysql -u dvdgp_mapas_usr -p dvdgp_mapas < seed_themes.sql

SET NAMES utf8mb4;

INSERT INTO `themes` (`id`, `name`, `description`, `config_json`, `preview_bg`, `preview_road`, `sort_order`, `active`) VALUES

('noir', 'Noir', 'Pure black background with white/gray roads - modern gallery aesthetic', 
'{"name":"Noir","description":"Pure black background with white/gray roads - modern gallery aesthetic","bg":"#000000","text":"#FFFFFF","gradient_color":"#000000","water":"#0A0A0A","parks":"#111111","road_motorway":"#FFFFFF","road_primary":"#E0E0E0","road_secondary":"#B0B0B0","road_tertiary":"#808080","road_residential":"#505050","road_default":"#808080"}',
'#000000', '#FFFFFF', 1, 1),

('midnight_blue', 'Midnight Blue', 'Deep navy background with gold/copper roads - luxury atlas aesthetic',
'{"name":"Midnight Blue","description":"Deep navy background with gold/copper roads - luxury atlas aesthetic","bg":"#0A1628","text":"#D4AF37","gradient_color":"#0A1628","water":"#061020","parks":"#0F2235","road_motorway":"#D4AF37","road_primary":"#C9A227","road_secondary":"#A8893A","road_tertiary":"#8B7355","road_residential":"#6B5B4F","road_default":"#8B7355"}',
'#0A1628', '#D4AF37', 2, 1),

('neon_cyberpunk', 'Neon Cyberpunk', 'Dark background with electric pink/cyan - bold night city vibes',
'{"name":"Neon Cyberpunk","description":"Dark background with electric pink/cyan - bold night city vibes","bg":"#0D0D1A","text":"#00FFFF","gradient_color":"#0D0D1A","water":"#0A0A15","parks":"#151525","road_motorway":"#FF00FF","road_primary":"#00FFFF","road_secondary":"#00C8C8","road_tertiary":"#0098A0","road_residential":"#006870","road_default":"#0098A0"}',
'#0D0D1A', '#00FFFF', 3, 1),

('blueprint', 'Blueprint', 'Classic architectural blueprint - technical drawing aesthetic',
'{"name":"Blueprint","description":"Classic architectural blueprint - technical drawing aesthetic","bg":"#1A3A5C","text":"#E8F4FF","gradient_color":"#1A3A5C","water":"#0F2840","parks":"#1E4570","road_motorway":"#E8F4FF","road_primary":"#C5DCF0","road_secondary":"#9FC5E8","road_tertiary":"#7BAED4","road_residential":"#5A96C0","road_default":"#7BAED4"}',
'#1A3A5C', '#E8F4FF', 4, 1),

('japanese_ink', 'Japanese Ink', 'Traditional ink wash inspired - minimalist with subtle red accent',
'{"name":"Japanese Ink","description":"Traditional ink wash inspired - minimalist with subtle red accent","bg":"#FAF8F5","text":"#2C2C2C","gradient_color":"#FAF8F5","water":"#E8E4E0","parks":"#F0EDE8","road_motorway":"#8B2500","road_primary":"#4A4A4A","road_secondary":"#6A6A6A","road_tertiary":"#909090","road_residential":"#B8B8B8","road_default":"#909090"}',
'#FAF8F5', '#4A4A4A', 5, 1),

('warm_beige', 'Warm Beige', 'Earthy warm neutrals with sepia tones - vintage map aesthetic',
'{"name":"Warm Beige","description":"Earthy warm neutrals with sepia tones - vintage map aesthetic","bg":"#F5F0E8","text":"#6B5B4F","gradient_color":"#F5F0E8","water":"#DDD5C8","parks":"#E8E4D8","road_motorway":"#8B7355","road_primary":"#A08B70","road_secondary":"#B5A48E","road_tertiary":"#C9BBAA","road_residential":"#D9CFC2","road_default":"#C9BBAA"}',
'#F5F0E8', '#8B7355', 6, 1),

('ocean', 'Ocean', 'Various blues and teals - perfect for coastal cities',
'{"name":"Ocean","description":"Various blues and teals - perfect for coastal cities","bg":"#F0F8FA","text":"#1A5F7A","gradient_color":"#F0F8FA","water":"#B8D8E8","parks":"#D8EAE8","road_motorway":"#1A5F7A","road_primary":"#2A7A9A","road_secondary":"#4A9AB8","road_tertiary":"#70B8D0","road_residential":"#A0D0E0","road_default":"#4A9AB8"}',
'#F0F8FA', '#1A5F7A', 7, 1),

('sunset', 'Sunset', 'Warm oranges and pinks on soft peach - dreamy golden hour aesthetic',
'{"name":"Sunset","description":"Warm oranges and pinks on soft peach - dreamy golden hour aesthetic","bg":"#FDF5F0","text":"#C45C3E","gradient_color":"#FDF5F0","water":"#F0D8D0","parks":"#F8E8E0","road_motorway":"#C45C3E","road_primary":"#D87A5A","road_secondary":"#E8A088","road_tertiary":"#F0B8A8","road_residential":"#F5D0C8","road_default":"#E8A088"}',
'#FDF5F0', '#C45C3E', 8, 1),

('forest', 'Forest', 'Deep greens and sage tones - organic botanical aesthetic',
'{"name":"Forest","description":"Deep greens and sage tones - organic botanical aesthetic","bg":"#F0F4F0","text":"#2D4A3E","gradient_color":"#F0F4F0","water":"#B8D4D4","parks":"#D4E8D4","road_motorway":"#2D4A3E","road_primary":"#3D6B55","road_secondary":"#5A8A70","road_tertiary":"#7AAA90","road_residential":"#A0C8B0","road_default":"#7AAA90"}',
'#F0F4F0', '#2D4A3E', 9, 1),

('terracotta', 'Terracotta', 'Mediterranean warmth - burnt orange and clay tones on cream',
'{"name":"Terracotta","description":"Mediterranean warmth - burnt orange and clay tones on cream","bg":"#F5EDE4","text":"#8B4513","gradient_color":"#F5EDE4","water":"#A8C4C4","parks":"#E8E0D0","road_motorway":"#A0522D","road_primary":"#B8653A","road_secondary":"#C9846A","road_tertiary":"#D9A08A","road_residential":"#E5C4B0","road_default":"#D9A08A"}',
'#F5EDE4', '#A0522D', 10, 1),

('pastel_dream', 'Pastel Dream', 'Soft muted pastels with dusty blues and mauves - dreamy artistic aesthetic',
'{"name":"Pastel Dream","description":"Soft muted pastels with dusty blues and mauves - dreamy artistic aesthetic","bg":"#FAF7F2","text":"#5D5A6D","gradient_color":"#FAF7F2","water":"#D4E4ED","parks":"#E8EDE4","road_motorway":"#7B8794","road_primary":"#9BA4B0","road_secondary":"#B5AEBB","road_tertiary":"#C9C0C9","road_residential":"#D8D2D8","road_default":"#C9C0C9"}',
'#FAF7F2', '#7B8794', 11, 1),

('copper_patina', 'Copper Patina', 'Oxidized copper aesthetic - teal-green patina with copper accents',
'{"name":"Copper Patina","description":"Oxidized copper aesthetic - teal-green patina with copper accents","bg":"#E8F0F0","text":"#2A5A5A","gradient_color":"#E8F0F0","water":"#C0D8D8","parks":"#D8E8E0","road_motorway":"#B87333","road_primary":"#5A8A8A","road_secondary":"#6B9E9E","road_tertiary":"#88B4B4","road_residential":"#A8CCCC","road_default":"#88B4B4"}',
'#E8F0F0', '#B87333', 12, 1),

('autumn', 'Autumn', 'Burnt oranges, deep reds, golden yellows - seasonal warmth',
'{"name":"Autumn","description":"Burnt oranges, deep reds, golden yellows - seasonal warmth","bg":"#FBF7F0","text":"#8B4513","gradient_color":"#FBF7F0","water":"#D8CFC0","parks":"#E8E0D0","road_motorway":"#8B2500","road_primary":"#B8450A","road_secondary":"#CC7A30","road_tertiary":"#D9A050","road_residential":"#E8C888","road_default":"#CC7A30"}',
'#FBF7F0', '#8B2500', 13, 1),

('monochrome_blue', 'Monochrome Blue', 'Single blue color family with varying saturation - clean and cohesive',
'{"name":"Monochrome Blue","description":"Single blue color family with varying saturation - clean and cohesive","bg":"#F5F8FA","text":"#1A3A5C","gradient_color":"#F5F8FA","water":"#D0E0F0","parks":"#E0EAF2","road_motorway":"#1A3A5C","road_primary":"#2A5580","road_secondary":"#4A7AA8","road_tertiary":"#7AA0C8","road_residential":"#A8C4E0","road_default":"#4A7AA8"}',
'#F5F8FA', '#1A3A5C', 14, 1),

('contrast_zones', 'Contrast Zones', 'Strong contrast showing urban density - darker in center, lighter at edges',
'{"name":"Contrast Zones","description":"Strong contrast showing urban density - darker in center, lighter at edges","bg":"#FFFFFF","text":"#000000","gradient_color":"#FFFFFF","water":"#B0B0B0","parks":"#ECECEC","road_motorway":"#000000","road_primary":"#0F0F0F","road_secondary":"#252525","road_tertiary":"#404040","road_residential":"#5A5A5A","road_default":"#404040"}',
'#FFFFFF', '#000000', 15, 1),

('feature_based', 'Feature-Based Shading', 'Different shades for different road types and features with clear hierarchy',
'{"name":"Feature-Based Shading","description":"Different shades for different road types and features with clear hierarchy","bg":"#FFFFFF","text":"#000000","gradient_color":"#FFFFFF","water":"#C0C0C0","parks":"#F0F0F0","road_motorway":"#0A0A0A","road_primary":"#1A1A1A","road_secondary":"#2A2A2A","road_tertiary":"#3A3A3A","road_residential":"#4A4A4A","road_default":"#3A3A3A"}',
'#FFFFFF', '#0A0A0A', 16, 1),

('gradient_roads', 'Gradient Roads', 'Smooth gradient from dark center to light edges with subtle features',
'{"name":"Gradient Roads","description":"Smooth gradient from dark center to light edges with subtle features","bg":"#FFFFFF","text":"#000000","gradient_color":"#FFFFFF","water":"#D5D5D5","parks":"#EFEFEF","road_motorway":"#050505","road_primary":"#151515","road_secondary":"#2A2A2A","road_tertiary":"#404040","road_residential":"#555555","road_default":"#404040"}',
'#FFFFFF', '#050505', 17, 1);

SELECT CONCAT('Inserted ', ROW_COUNT(), ' themes') AS message;
