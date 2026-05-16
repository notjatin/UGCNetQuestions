// This file holds the binding of quess 
import quesData from "./questions.json" with { type: 'json' };

/**
 * Generates HTML structure for a list of quess
 * @param {Object} quesObj - Single ques object in given JSON
 * @param {number} quesId - ques ID
 * @returns {string} HTML string
 */

function createQuesElement(quesObj, quesId) {
  // Create main container
  const quesItem = document.createElement('div');
  quesItem.className = 'ques-list-item';
  quesItem.dataset.quesId = quesId;

  // Create ques description
  const quesDesc = document.createElement('div');
  quesDesc.className = 'ques-desc';
  quesDesc.innerHTML = `
    <span>${quesObj.ques["ques-head"]}:</span>
    <span>${quesObj.ques["ques-desc"]}</span>
  `;

  // Create options list
  const optionsList = document.createElement('div');
  optionsList.className = 'ques-option-list';

  quesObj.options.forEach((opt, index) => {
    const optionItem = document.createElement('div');
    optionItem.className = 'ques-option-list-item';
    optionItem.dataset.quesOptionId = index + 1;
    optionItem.innerHTML = `
      <span>${opt["option-head"]}</span>
      <span>${opt["option-desc"]}</span>
    `;
    
    // Optional: Add click handler
    // optionItem.addEventListener('click', (e) => {
    //   console.log(`Selected: ques ${quesId}, Option ${index + 1}`);
    //   // Your logic here
    // });
    
    optionsList.appendChild(optionItem);
  });

  quesItem.appendChild(quesDesc);
  quesItem.appendChild(optionsList);
  
  return quesItem;
}

// Core function
const quesListHolder = document.querySelector('.ques-list');
quesData.forEach((q, index) => {
  const quesEl = createQuesElement(q, index + 1);
  console.log(quesEl, quesListHolder);
  quesListHolder.appendChild(quesEl);
});

