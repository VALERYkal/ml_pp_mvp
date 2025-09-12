// Script de test d'encodage pour validation rapide
import fs from 'fs';
import path from 'path';

const testStrings = [
  'Rôle',
  'Entrées', 
  'Dépôt',
  'Réceptions',
  'Connexion réussie',
  'Aucun profil trouvé'
];

const problematicStrings = [
  'RÃ´le',
  'EntrÃ©es',
  'DÃ©pÃ´t', 
  'RÃ©ceptions',
  'Connexion rÃ©ussie',
  'Aucun profil trouvÃ©'
];

function checkFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Vérifier les chaînes problématiques
    const foundProblems = [];
    problematicStrings.forEach(problem => {
      if (content.includes(problem)) {
        foundProblems.push(problem);
      }
    });
    
    // Vérifier les chaînes correctes
    const foundCorrect = [];
    testStrings.forEach(correct => {
      if (content.includes(correct)) {
        foundCorrect.push(correct);
      }
    });
    
    if (foundProblems.length > 0) {
      console.log(`❌ ${filePath}:`);
      foundProblems.forEach(problem => {
        console.log(`   - Problème: "${problem}"`);
      });
    }
    
    if (foundCorrect.length > 0 && foundProblems.length === 0) {
      console.log(`✅ ${filePath}: Accents corrects`);
    }
    
    return { problems: foundProblems, correct: foundCorrect };
  } catch (error) {
    console.log(`⚠️  ${filePath}: Erreur de lecture - ${error.message}`);
    return { problems: [], correct: [] };
  }
}

function walkDirectory(dir) {
  const results = { total: 0, problems: 0, correct: 0 };
  
  try {
    const files = fs.readdirSync(dir);
    
    for (const file of files) {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules') {
        const subResults = walkDirectory(filePath);
        results.total += subResults.total;
        results.problems += subResults.problems;
        results.correct += subResults.correct;
      } else if (file.endsWith('.dart') || file.endsWith('.md')) {
        results.total++;
        const check = checkFile(filePath);
        if (check.problems.length > 0) {
          results.problems++;
        } else if (check.correct.length > 0) {
          results.correct++;
        }
      }
    }
  } catch (error) {
    console.log(`⚠️  Erreur lecture dossier ${dir}: ${error.message}`);
  }
  
  return results;
}

console.log('🔍 Test d\'encodage UTF-8 - Recherche des artefacts...\n');

const results = walkDirectory('lib');

console.log('\n📊 Résumé:');
console.log(`   Total fichiers: ${results.total}`);
console.log(`   ✅ Accents corrects: ${results.correct}`);
console.log(`   ❌ Problèmes détectés: ${results.problems}`);

if (results.problems === 0) {
  console.log('\n🎉 Tous les fichiers ont un encodage correct !');
  process.exit(0);
} else {
  console.log('\n⚠️  Des problèmes d\'encodage ont été détectés.');
  process.exit(1);
}