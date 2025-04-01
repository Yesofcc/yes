// Z�kladn� premenn�
let playerCash = 0;
let playerBank = 0;

// Event listener pre prij�manie spr�v z hern�ho klienta
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openDeposit') {
        // Aktualiz�cia �dajov o hr��ovi
        playerCash = data.playerCash || 0;
        playerBank = data.playerBank || 0;
        
        // Zobrazenie vkladov�ho formul�ra
        document.getElementById('deposit-container').style.display = 'flex';
    } 
    else if (data.action === 'openWithdraw') {
        // Aktualiz�cia �dajov o hr��ovi
        playerCash = data.playerCash || 0;
        playerBank = data.playerBank || 0;
        
        // Zobrazenie v�berov�ho formul�ra
        document.getElementById('withdraw-container').style.display = 'flex';
    }
    else if (data.action === 'openTransfer') {
        // Aktualiz�cia �dajov o hr��ovi
        playerCash = data.playerCash || 0;
        playerBank = data.playerBank || 0;
        
        // Zobrazenie formul�ra na prevod pe�az�
        document.getElementById('transfer-container').style.display = 'flex';
    }
    else if (data.action === 'closeAll') {
        // Zatvorenie v�etk�ch formul�rov
        document.getElementById('deposit-container').style.display = 'none';
        document.getElementById('withdraw-container').style.display = 'none';
        document.getElementById('transfer-container').style.display = 'none';
    }
});

// Event listeners pre tla�idl� r�chlych s�m
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

// Event listener pre tla�idlo vkladu
document.getElementById('deposit-btn').addEventListener('click', function() {
    const amount = parseInt(document.getElementById('deposit-amount').value);
    
    if (amount && amount > 0) {
        // Odoslanie inform�cie o vklade do hry
        fetch(`https://${GetParentResourceName()}/depositMoney`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount })
        });
        
        // Zatvorenie formul�ra
        document.getElementById('deposit-container').style.display = 'none';
        document.getElementById('deposit-amount').value = '';
    }
});

// Event listener pre tla�idlo v�beru
document.getElementById('withdraw-btn').addEventListener('click', function() {
    const amount = parseInt(document.getElementById('withdraw-amount').value);
    
    if (amount && amount > 0) {
        // Odoslanie inform�cie o v�bere do hry
        fetch(`https://${GetParentResourceName()}/withdrawMoney`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount })
        });
        
        // Zatvorenie formul�ra
        document.getElementById('withdraw-container').style.display = 'none';
        document.getElementById('withdraw-amount').value = '';
    }
});

// Event listener pre tla�idlo prevodu
document.getElementById('transfer-btn').addEventListener('click', function() {
    const id = document.getElementById('transfer-id').value;
    const amount = parseInt(document.getElementById('transfer-amount').value);
    
    if (id && amount && amount > 0) {
        // Odoslanie inform�cie o prevode do hry
        fetch(`https://${GetParentResourceName()}/transferMoney`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                targetId: id,
                amount: amount 
            })
        });
        
        // Zatvorenie formul�ra
        document.getElementById('transfer-container').style.display = 'none';
        document.getElementById('transfer-id').value = '';
        document.getElementById('transfer-amount').value = '';
    }
});

// Event listeners pre tla�idl� zru�enia
document.getElementById('cancel-btn').addEventListener('click', function() {
    document.getElementById('deposit-container').style.display = 'none';
    document.getElementById('deposit-amount').value = '';
    
    // Odoslanie inform�cie o zatvoren� do hry
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.getElementById('cancel-withdraw-btn').addEventListener('click', function() {
    document.getElementById('withdraw-container').style.display = 'none';
    document.getElementById('withdraw-amount').value = '';
    
    // Odoslanie inform�cie o zatvoren� do hry
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
    
    // Odoslanie inform�cie o zatvoren� do hry
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Funkcia pre z�skanie n�zvu rodi�ovsk�ho resource
function GetParentResourceName() {
    try {
        return window.GetParentResourceName();
    } catch (e) {
        return 'qb-banka';
    }
}