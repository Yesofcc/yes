// Základné premenné
let playerCash = 0;
let playerBank = 0;

// Event listener pre prijímanie správ z herného klienta
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openDeposit') {
        // Aktualizácia údajov o hráèovi
        playerCash = data.playerCash || 0;
        playerBank = data.playerBank || 0;
        
        // Zobrazenie vkladového formulára
        document.getElementById('deposit-container').style.display = 'flex';
    } 
    else if (data.action === 'openWithdraw') {
        // Aktualizácia údajov o hráèovi
        playerCash = data.playerCash || 0;
        playerBank = data.playerBank || 0;
        
        // Zobrazenie výberového formulára
        document.getElementById('withdraw-container').style.display = 'flex';
    }
    else if (data.action === 'openTransfer') {
        // Aktualizácia údajov o hráèovi
        playerCash = data.playerCash || 0;
        playerBank = data.playerBank || 0;
        
        // Zobrazenie formulára na prevod peòazí
        document.getElementById('transfer-container').style.display = 'flex';
    }
    else if (data.action === 'closeAll') {
        // Zatvorenie všetkých formulárov
        document.getElementById('deposit-container').style.display = 'none';
        document.getElementById('withdraw-container').style.display = 'none';
        document.getElementById('transfer-container').style.display = 'none';
    }
});

// Event listeners pre tlaèidlá rýchlych súm
document.querySelectorAll('.quick-amount').forEach(button => {
    button.addEventListener('click', function() {
        const amount = this.dataset.amount;
        const parentContainer = this.closest('div[id$="-container"]');
        let inputField;
        
        if (parentContainer.id === 'deposit-container') {
            inputField = document.getElementById('deposit-amount');
            if (amount === 'all') {
                inputField.value = playerCash;
            } else {
                inputField.value = amount;
            }
        } 
        else if (parentContainer.id === 'withdraw-container') {
            inputField = document.getElementById('withdraw-amount');
            if (amount === 'all') {
                inputField.value = playerBank;
            } else {
                inputField.value = amount;
            }
        }
    });
});

// Event listener pre tlaèidlo vkladu
document.getElementById('deposit-btn').addEventListener('click', function() {
    const amount = parseInt(document.getElementById('deposit-amount').value);
    
    if (amount && amount > 0) {
        // Odoslanie informácie o vklade do hry
        fetch(`https://${GetParentResourceName()}/depositMoney`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount })
        });
        
        // Zatvorenie formulára
        document.getElementById('deposit-container').style.display = 'none';
        document.getElementById('deposit-amount').value = '';
    }
});

// Event listener pre tlaèidlo výberu
document.getElementById('withdraw-btn').addEventListener('click', function() {
    const amount = parseInt(document.getElementById('withdraw-amount').value);
    
    if (amount && amount > 0) {
        // Odoslanie informácie o výbere do hry
        fetch(`https://${GetParentResourceName()}/withdrawMoney`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount })
        });
        
        // Zatvorenie formulára
        document.getElementById('withdraw-container').style.display = 'none';
        document.getElementById('withdraw-amount').value = '';
    }
});

// Event listener pre tlaèidlo prevodu
document.getElementById('transfer-btn').addEventListener('click', function() {
    const id = document.getElementById('transfer-id').value;
    const amount = parseInt(document.getElementById('transfer-amount').value);
    
    if (id && amount && amount > 0) {
        // Odoslanie informácie o prevode do hry
        fetch(`https://${GetParentResourceName()}/transferMoney`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                targetId: id,
                amount: amount 
            })
        });
        
        // Zatvorenie formulára
        document.getElementById('transfer-container').style.display = 'none';
        document.getElementById('transfer-id').value = '';
        document.getElementById('transfer-amount').value = '';
    }
});

// Event listeners pre tlaèidlá zrušenia
document.getElementById('cancel-btn').addEventListener('click', function() {
    document.getElementById('deposit-container').style.display = 'none';
    document.getElementById('deposit-amount').value = '';
    
    // Odoslanie informácie o zatvorení do hry
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.getElementById('cancel-withdraw-btn').addEventListener('click', function() {
    document.getElementById('withdraw-container').style.display = 'none';
    document.getElementById('withdraw-amount').value = '';
    
    // Odoslanie informácie o zatvorení do hry
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.getElementById('cancel-transfer-btn').addEventListener('click', function() {
    document.getElementById('transfer-container').style.display = 'none';
    document.getElementById('transfer-id').value = '';
    document.getElementById('transfer-amount').value = '';
    
    // Odoslanie informácie o zatvorení do hry
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Funkcia pre získanie názvu rodièovského resource
function GetParentResourceName() {
    try {
        return window.GetParentResourceName();
    } catch (e) {
        return 'qb-banka';
    }
}