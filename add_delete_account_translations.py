import json
import os

translations_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "translations")

translations = {
    "tr": {
        "delete_account": "Hesabı Sil",
        "delete_account_title": "Hesabınız silinsin mi?",
        "delete_account_body": "Hesabınız ve buluttaki tüm odak istatistikleriniz (oturumlar, dakikalar, seri ve günlük geçmiş) kalıcı olarak silinir. Bu işlem geri alınamaz.",
        "delete_account_purchase_note": "Premium satın alma kaydınız Google Play'de kalır. Hesabı silmek aktif bir aboneliği iptal etmez; aboneliğinizi Google Play'den ayrıca iptal edin.",
        "delete_account_type_prompt": "Onaylamak için {} yazın",
        "delete_account_confirm_word": "SİL",
        "delete_account_confirm": "Kalıcı Olarak Sil",
        "delete_account_error": "Hesap silinemedi. İnternet bağlantınızı kontrol edip tekrar deneyin. Sorun sürerse web sitemizden silme talebi gönderebilirsiniz.",
        "delete_account_success": "Hesabınız ve buluttaki verileriniz silindi."
    },
    "en": {
        "delete_account": "Delete Account",
        "delete_account_title": "Delete your account?",
        "delete_account_body": "Your account and all of your focus stats stored in the cloud (sessions, minutes, streak and daily history) will be permanently deleted. This can't be undone.",
        "delete_account_purchase_note": "Your Premium purchase record stays with Google Play. Deleting your account does not cancel an active subscription; cancel it separately in Google Play.",
        "delete_account_type_prompt": "Type {} to confirm",
        "delete_account_confirm_word": "DELETE",
        "delete_account_confirm": "Delete Permanently",
        "delete_account_error": "Couldn't delete your account. Check your internet connection and try again. If the problem continues, you can request deletion on our website.",
        "delete_account_success": "Your account and cloud data have been deleted."
    },
    "de": {
        "delete_account": "Konto löschen",
        "delete_account_title": "Konto löschen?",
        "delete_account_body": "Dein Konto und alle in der Cloud gespeicherten Fokus-Statistiken (Sitzungen, Minuten, Serie und Tagesverlauf) werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.",
        "delete_account_purchase_note": "Dein Premium-Kaufnachweis bleibt bei Google Play. Das Löschen des Kontos kündigt kein aktives Abo; kündige es separat in Google Play.",
        "delete_account_type_prompt": "Gib {} ein, um zu bestätigen",
        "delete_account_confirm_word": "LÖSCHEN",
        "delete_account_confirm": "Endgültig löschen",
        "delete_account_error": "Das Konto konnte nicht gelöscht werden. Prüfe deine Internetverbindung und versuche es erneut. Falls das Problem bleibt, kannst du die Löschung auf unserer Website beantragen.",
        "delete_account_success": "Dein Konto und deine Cloud-Daten wurden gelöscht."
    },
    "es": {
        "delete_account": "Eliminar cuenta",
        "delete_account_title": "¿Eliminar tu cuenta?",
        "delete_account_body": "Tu cuenta y todas tus estadísticas de enfoque guardadas en la nube (sesiones, minutos, racha e historial diario) se eliminarán de forma permanente. Esta acción no se puede deshacer.",
        "delete_account_purchase_note": "El registro de tu compra Premium permanece en Google Play. Eliminar la cuenta no cancela una suscripción activa; cancélala por separado en Google Play.",
        "delete_account_type_prompt": "Escribe {} para confirmar",
        "delete_account_confirm_word": "ELIMINAR",
        "delete_account_confirm": "Eliminar definitivamente",
        "delete_account_error": "No se pudo eliminar la cuenta. Revisa tu conexión a internet e inténtalo de nuevo. Si el problema continúa, puedes solicitar la eliminación en nuestro sitio web.",
        "delete_account_success": "Tu cuenta y tus datos en la nube se han eliminado."
    },
    "fr": {
        "delete_account": "Supprimer le compte",
        "delete_account_title": "Supprimer votre compte ?",
        "delete_account_body": "Votre compte et toutes vos statistiques de concentration stockées dans le cloud (sessions, minutes, série et historique quotidien) seront définitivement supprimés. Cette action est irréversible.",
        "delete_account_purchase_note": "La trace de votre achat Premium reste sur Google Play. Supprimer le compte n'annule pas un abonnement actif ; annulez-le séparément dans Google Play.",
        "delete_account_type_prompt": "Saisissez {} pour confirmer",
        "delete_account_confirm_word": "SUPPRIMER",
        "delete_account_confirm": "Supprimer définitivement",
        "delete_account_error": "Impossible de supprimer le compte. Vérifiez votre connexion Internet et réessayez. Si le problème persiste, vous pouvez demander la suppression sur notre site web.",
        "delete_account_success": "Votre compte et vos données cloud ont été supprimés."
    },
    "it": {
        "delete_account": "Elimina account",
        "delete_account_title": "Eliminare il tuo account?",
        "delete_account_body": "Il tuo account e tutte le statistiche di concentrazione salvate nel cloud (sessioni, minuti, serie e cronologia giornaliera) verranno eliminati definitivamente. L'operazione non può essere annullata.",
        "delete_account_purchase_note": "La registrazione del tuo acquisto Premium resta su Google Play. Eliminare l'account non annulla un abbonamento attivo; annullalo separatamente su Google Play.",
        "delete_account_type_prompt": "Digita {} per confermare",
        "delete_account_confirm_word": "ELIMINA",
        "delete_account_confirm": "Elimina definitivamente",
        "delete_account_error": "Impossibile eliminare l'account. Controlla la connessione a Internet e riprova. Se il problema persiste, puoi richiedere l'eliminazione sul nostro sito web.",
        "delete_account_success": "Il tuo account e i dati nel cloud sono stati eliminati."
    },
    "pt": {
        "delete_account": "Excluir conta",
        "delete_account_title": "Excluir sua conta?",
        "delete_account_body": "Sua conta e todas as suas estatísticas de foco salvas na nuvem (sessões, minutos, sequência e histórico diário) serão excluídas permanentemente. Esta ação não pode ser desfeita.",
        "delete_account_purchase_note": "O registro da sua compra Premium permanece no Google Play. Excluir a conta não cancela uma assinatura ativa; cancele-a separadamente no Google Play.",
        "delete_account_type_prompt": "Digite {} para confirmar",
        "delete_account_confirm_word": "EXCLUIR",
        "delete_account_confirm": "Excluir permanentemente",
        "delete_account_error": "Não foi possível excluir a conta. Verifique sua conexão com a internet e tente novamente. Se o problema continuar, você pode solicitar a exclusão em nosso site.",
        "delete_account_success": "Sua conta e seus dados na nuvem foram excluídos."
    },
    "nl": {
        "delete_account": "Account verwijderen",
        "delete_account_title": "Je account verwijderen?",
        "delete_account_body": "Je account en al je focusstatistieken in de cloud (sessies, minuten, reeks en dagelijkse geschiedenis) worden permanent verwijderd. Dit kan niet ongedaan worden gemaakt.",
        "delete_account_purchase_note": "Het record van je Premium-aankoop blijft bij Google Play. Het verwijderen van je account zegt een actief abonnement niet op; zeg het apart op in Google Play.",
        "delete_account_type_prompt": "Typ {} om te bevestigen",
        "delete_account_confirm_word": "VERWIJDEREN",
        "delete_account_confirm": "Definitief verwijderen",
        "delete_account_error": "Je account kon niet worden verwijderd. Controleer je internetverbinding en probeer het opnieuw. Blijft het probleem bestaan, dan kun je verwijdering aanvragen via onze website.",
        "delete_account_success": "Je account en clouddata zijn verwijderd."
    },
    "pl": {
        "delete_account": "Usuń konto",
        "delete_account_title": "Usunąć konto?",
        "delete_account_body": "Twoje konto i wszystkie statystyki skupienia zapisane w chmurze (sesje, minuty, seria i historia dzienna) zostaną trwale usunięte. Tej operacji nie można cofnąć.",
        "delete_account_purchase_note": "Zapis zakupu Premium pozostaje w Google Play. Usunięcie konta nie anuluje aktywnej subskrypcji; anuluj ją osobno w Google Play.",
        "delete_account_type_prompt": "Wpisz {}, aby potwierdzić",
        "delete_account_confirm_word": "USUŃ",
        "delete_account_confirm": "Usuń trwale",
        "delete_account_error": "Nie udało się usunąć konta. Sprawdź połączenie z internetem i spróbuj ponownie. Jeśli problem będzie się powtarzał, możesz poprosić o usunięcie na naszej stronie internetowej.",
        "delete_account_success": "Twoje konto i dane w chmurze zostały usunięte."
    },
    "sv": {
        "delete_account": "Radera konto",
        "delete_account_title": "Radera ditt konto?",
        "delete_account_body": "Ditt konto och all din fokusstatistik i molnet (sessioner, minuter, svit och daglig historik) raderas permanent. Detta går inte att ångra.",
        "delete_account_purchase_note": "Ditt Premium-köp finns kvar hos Google Play. Att radera kontot avslutar inte en aktiv prenumeration; avsluta den separat i Google Play.",
        "delete_account_type_prompt": "Skriv {} för att bekräfta",
        "delete_account_confirm_word": "RADERA",
        "delete_account_confirm": "Radera permanent",
        "delete_account_error": "Kontot kunde inte raderas. Kontrollera din internetanslutning och försök igen. Om problemet kvarstår kan du begära radering på vår webbplats.",
        "delete_account_success": "Ditt konto och dina molndata har raderats."
    },
    "ru": {
        "delete_account": "Удалить аккаунт",
        "delete_account_title": "Удалить аккаунт?",
        "delete_account_body": "Ваш аккаунт и вся статистика фокусировки в облаке (сессии, минуты, серия и история по дням) будут удалены навсегда. Это действие нельзя отменить.",
        "delete_account_purchase_note": "Запись о покупке Premium останется в Google Play. Удаление аккаунта не отменяет активную подписку; отмените её отдельно в Google Play.",
        "delete_account_type_prompt": "Введите {} для подтверждения",
        "delete_account_confirm_word": "УДАЛИТЬ",
        "delete_account_confirm": "Удалить навсегда",
        "delete_account_error": "Не удалось удалить аккаунт. Проверьте подключение к интернету и попробуйте снова. Если проблема сохранится, вы можете запросить удаление на нашем сайте.",
        "delete_account_success": "Ваш аккаунт и данные в облаке удалены."
    },
    "uk": {
        "delete_account": "Видалити акаунт",
        "delete_account_title": "Видалити акаунт?",
        "delete_account_body": "Ваш акаунт і вся статистика фокусування в хмарі (сесії, хвилини, серія та щоденна історія) будуть видалені назавжди. Цю дію неможливо скасувати.",
        "delete_account_purchase_note": "Запис про покупку Premium залишиться в Google Play. Видалення акаунта не скасовує активну підписку; скасуйте її окремо в Google Play.",
        "delete_account_type_prompt": "Введіть {} для підтвердження",
        "delete_account_confirm_word": "ВИДАЛИТИ",
        "delete_account_confirm": "Видалити назавжди",
        "delete_account_error": "Не вдалося видалити акаунт. Перевірте підключення до інтернету та спробуйте ще раз. Якщо проблема не зникне, ви можете надіслати запит на видалення на нашому сайті.",
        "delete_account_success": "Ваш акаунт і дані в хмарі видалено."
    },
    "el": {
        "delete_account": "Διαγραφή λογαριασμού",
        "delete_account_title": "Διαγραφή του λογαριασμού σας;",
        "delete_account_body": "Ο λογαριασμός σας και όλα τα στατιστικά συγκέντρωσης στο cloud (συνεδρίες, λεπτά, σερί και ημερήσιο ιστορικό) θα διαγραφούν οριστικά. Αυτή η ενέργεια δεν αναιρείται.",
        "delete_account_purchase_note": "Η καταγραφή της αγοράς Premium παραμένει στο Google Play. Η διαγραφή του λογαριασμού δεν ακυρώνει μια ενεργή συνδρομή· ακυρώστε την ξεχωριστά στο Google Play.",
        "delete_account_type_prompt": "Πληκτρολογήστε {} για επιβεβαίωση",
        "delete_account_confirm_word": "ΔΙΑΓΡΑΦΗ",
        "delete_account_confirm": "Οριστική διαγραφή",
        "delete_account_error": "Δεν ήταν δυνατή η διαγραφή του λογαριασμού. Ελέγξτε τη σύνδεσή σας στο διαδίκτυο και δοκιμάστε ξανά. Αν το πρόβλημα συνεχιστεί, μπορείτε να ζητήσετε διαγραφή από τον ιστότοπό μας.",
        "delete_account_success": "Ο λογαριασμός σας και τα δεδομένα στο cloud διαγράφηκαν."
    },
    "ar": {
        "delete_account": "حذف الحساب",
        "delete_account_title": "هل تريد حذف حسابك؟",
        "delete_account_body": "سيتم حذف حسابك وجميع إحصائيات التركيز المحفوظة في السحابة (الجلسات والدقائق والسلسلة والسجل اليومي) نهائيًا. لا يمكن التراجع عن هذا الإجراء.",
        "delete_account_purchase_note": "يبقى سجل شراء Premium لدى Google Play. حذف الحساب لا يلغي أي اشتراك نشط؛ قم بإلغائه بشكل منفصل من Google Play.",
        "delete_account_type_prompt": "اكتب {} للتأكيد",
        "delete_account_confirm_word": "حذف",
        "delete_account_confirm": "حذف نهائي",
        "delete_account_error": "تعذّر حذف الحساب. تحقق من اتصالك بالإنترنت وحاول مرة أخرى. إذا استمرت المشكلة، يمكنك طلب الحذف عبر موقعنا الإلكتروني.",
        "delete_account_success": "تم حذف حسابك وبياناتك في السحابة."
    },
    "ur": {
        "delete_account": "اکاؤنٹ حذف کریں",
        "delete_account_title": "کیا آپ اپنا اکاؤنٹ حذف کرنا چاہتے ہیں؟",
        "delete_account_body": "آپ کا اکاؤنٹ اور کلاؤڈ میں محفوظ تمام فوکس اعداد و شمار (سیشنز، منٹ، تسلسل اور روزانہ تاریخ) مستقل طور پر حذف ہو جائیں گے۔ یہ عمل واپس نہیں لیا جا سکتا۔",
        "delete_account_purchase_note": "آپ کی Premium خریداری کا ریکارڈ Google Play پر رہتا ہے۔ اکاؤنٹ حذف کرنے سے فعال سبسکرپشن منسوخ نہیں ہوتی؛ اسے Google Play سے الگ سے منسوخ کریں۔",
        "delete_account_type_prompt": "تصدیق کے لیے {} لکھیں",
        "delete_account_confirm_word": "حذف",
        "delete_account_confirm": "مستقل طور پر حذف کریں",
        "delete_account_error": "اکاؤنٹ حذف نہیں ہو سکا۔ اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔ اگر مسئلہ برقرار رہے تو آپ ہماری ویب سائٹ پر حذف کرنے کی درخواست بھیج سکتے ہیں۔",
        "delete_account_success": "آپ کا اکاؤنٹ اور کلاؤڈ ڈیٹا حذف کر دیا گیا۔"
    },
    "hi": {
        "delete_account": "खाता हटाएं",
        "delete_account_title": "अपना खाता हटाएं?",
        "delete_account_body": "आपका खाता और क्लाउड में सहेजे गए सभी फोकस आंकड़े (सत्र, मिनट, स्ट्रीक और दैनिक इतिहास) स्थायी रूप से हटा दिए जाएंगे। यह कार्रवाई पूर्ववत नहीं की जा सकती।",
        "delete_account_purchase_note": "आपकी Premium खरीद का रिकॉर्ड Google Play पर रहता है। खाता हटाने से सक्रिय सदस्यता रद्द नहीं होती; उसे Google Play में अलग से रद्द करें।",
        "delete_account_type_prompt": "पुष्टि के लिए {} लिखें",
        "delete_account_confirm_word": "हटाएं",
        "delete_account_confirm": "स्थायी रूप से हटाएं",
        "delete_account_error": "खाता हटाया नहीं जा सका। अपना इंटरनेट कनेक्शन जांचें और फिर से प्रयास करें। समस्या बनी रहे तो आप हमारी वेबसाइट पर हटाने का अनुरोध भेज सकते हैं।",
        "delete_account_success": "आपका खाता और क्लाउड डेटा हटा दिया गया है।"
    },
    "bn": {
        "delete_account": "অ্যাকাউন্ট মুছুন",
        "delete_account_title": "আপনার অ্যাকাউন্ট মুছবেন?",
        "delete_account_body": "আপনার অ্যাকাউন্ট এবং ক্লাউডে সংরক্ষিত সব ফোকাস পরিসংখ্যান (সেশন, মিনিট, স্ট্রিক ও দৈনিক ইতিহাস) স্থায়ীভাবে মুছে ফেলা হবে। এটি আর ফিরিয়ে আনা যাবে না।",
        "delete_account_purchase_note": "আপনার Premium কেনার রেকর্ড Google Play-তে থেকে যায়। অ্যাকাউন্ট মুছলে সক্রিয় সাবস্ক্রিপশন বাতিল হয় না; সেটি Google Play থেকে আলাদাভাবে বাতিল করুন।",
        "delete_account_type_prompt": "নিশ্চিত করতে {} লিখুন",
        "delete_account_confirm_word": "মুছুন",
        "delete_account_confirm": "স্থায়ীভাবে মুছুন",
        "delete_account_error": "অ্যাকাউন্ট মোছা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন। সমস্যা থেকে গেলে আমাদের ওয়েবসাইট থেকে মুছে ফেলার অনুরোধ পাঠাতে পারেন।",
        "delete_account_success": "আপনার অ্যাকাউন্ট ও ক্লাউড ডেটা মুছে ফেলা হয়েছে।"
    },
    "id": {
        "delete_account": "Hapus Akun",
        "delete_account_title": "Hapus akun Anda?",
        "delete_account_body": "Akun Anda dan semua statistik fokus yang tersimpan di cloud (sesi, menit, rentetan, dan riwayat harian) akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.",
        "delete_account_purchase_note": "Catatan pembelian Premium Anda tetap ada di Google Play. Menghapus akun tidak membatalkan langganan aktif; batalkan secara terpisah di Google Play.",
        "delete_account_type_prompt": "Ketik {} untuk mengonfirmasi",
        "delete_account_confirm_word": "HAPUS",
        "delete_account_confirm": "Hapus Permanen",
        "delete_account_error": "Akun tidak dapat dihapus. Periksa koneksi internet Anda dan coba lagi. Jika masalah berlanjut, Anda dapat mengajukan penghapusan melalui situs web kami.",
        "delete_account_success": "Akun dan data cloud Anda telah dihapus."
    },
    "vi": {
        "delete_account": "Xóa tài khoản",
        "delete_account_title": "Xóa tài khoản của bạn?",
        "delete_account_body": "Tài khoản và toàn bộ thống kê tập trung lưu trên đám mây (phiên, phút, chuỗi và lịch sử hằng ngày) sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác.",
        "delete_account_purchase_note": "Hồ sơ mua Premium của bạn vẫn được lưu trên Google Play. Xóa tài khoản không hủy gói đăng ký đang hoạt động; hãy hủy riêng trên Google Play.",
        "delete_account_type_prompt": "Nhập {} để xác nhận",
        "delete_account_confirm_word": "XÓA",
        "delete_account_confirm": "Xóa vĩnh viễn",
        "delete_account_error": "Không thể xóa tài khoản. Hãy kiểm tra kết nối internet và thử lại. Nếu sự cố vẫn tiếp diễn, bạn có thể yêu cầu xóa trên trang web của chúng tôi.",
        "delete_account_success": "Tài khoản và dữ liệu đám mây của bạn đã bị xóa."
    },
    "th": {
        "delete_account": "ลบบัญชี",
        "delete_account_title": "ต้องการลบบัญชีของคุณหรือไม่?",
        "delete_account_body": "บัญชีของคุณและสถิติการโฟกัสทั้งหมดที่เก็บไว้บนคลาวด์ (เซสชัน นาที สถิติต่อเนื่อง และประวัติรายวัน) จะถูกลบอย่างถาวร การดำเนินการนี้ไม่สามารถย้อนกลับได้",
        "delete_account_purchase_note": "บันทึกการซื้อ Premium ของคุณยังคงอยู่ใน Google Play การลบบัญชีไม่ได้ยกเลิกการสมัครสมาชิกที่ใช้งานอยู่ โปรดยกเลิกแยกต่างหากใน Google Play",
        "delete_account_type_prompt": "พิมพ์ {} เพื่อยืนยัน",
        "delete_account_confirm_word": "ลบ",
        "delete_account_confirm": "ลบถาวร",
        "delete_account_error": "ไม่สามารถลบบัญชีได้ โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ตแล้วลองอีกครั้ง หากยังมีปัญหา คุณสามารถส่งคำขอลบผ่านเว็บไซต์ของเราได้",
        "delete_account_success": "ลบบัญชีและข้อมูลบนคลาวด์ของคุณแล้ว"
    },
    "ja": {
        "delete_account": "アカウントを削除",
        "delete_account_title": "アカウントを削除しますか？",
        "delete_account_body": "アカウントと、クラウドに保存されたすべての集中統計（セッション、分数、連続記録、日別履歴）が完全に削除されます。この操作は取り消せません。",
        "delete_account_purchase_note": "Premiumの購入記録はGoogle Playに残ります。アカウントを削除しても有効なサブスクリプションは解約されません。Google Playで別途解約してください。",
        "delete_account_type_prompt": "確認のため「{}」と入力してください",
        "delete_account_confirm_word": "削除",
        "delete_account_confirm": "完全に削除",
        "delete_account_error": "アカウントを削除できませんでした。インターネット接続を確認して、もう一度お試しください。問題が続く場合は、ウェブサイトから削除をリクエストできます。",
        "delete_account_success": "アカウントとクラウドのデータを削除しました。"
    },
    "ko": {
        "delete_account": "계정 삭제",
        "delete_account_title": "계정을 삭제할까요?",
        "delete_account_body": "계정과 클라우드에 저장된 모든 집중 통계(세션, 시간(분), 연속 기록, 일별 기록)가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.",
        "delete_account_purchase_note": "Premium 구매 기록은 Google Play에 남아 있습니다. 계정을 삭제해도 활성 구독은 취소되지 않으니 Google Play에서 별도로 취소하세요.",
        "delete_account_type_prompt": "확인하려면 {}을(를) 입력하세요",
        "delete_account_confirm_word": "삭제",
        "delete_account_confirm": "영구 삭제",
        "delete_account_error": "계정을 삭제하지 못했습니다. 인터넷 연결을 확인한 후 다시 시도하세요. 문제가 계속되면 웹사이트에서 삭제를 요청할 수 있습니다.",
        "delete_account_success": "계정과 클라우드 데이터가 삭제되었습니다."
    },
    "zh": {
        "delete_account": "删除账户",
        "delete_account_title": "要删除你的账户吗？",
        "delete_account_body": "你的账户以及保存在云端的所有专注统计（会话、分钟数、连续记录和每日历史）将被永久删除。此操作无法撤销。",
        "delete_account_purchase_note": "你的 Premium 购买记录会保留在 Google Play 中。删除账户不会取消有效的订阅，请在 Google Play 中单独取消。",
        "delete_account_type_prompt": "输入“{}”以确认",
        "delete_account_confirm_word": "删除",
        "delete_account_confirm": "永久删除",
        "delete_account_error": "无法删除账户。请检查网络连接后重试。如果问题仍然存在，你可以在我们的网站上提交删除请求。",
        "delete_account_success": "你的账户和云端数据已删除。"
    },
}

expected_keys = set(translations["en"])
for lang_code, values in translations.items():
    assert set(values) == expected_keys, lang_code

for filename in sorted(os.listdir(translations_dir)):
    if not filename.endswith(".json"):
        continue
    lang_code = filename[:-5]
    if lang_code not in translations:
        raise SystemExit(f"Missing delete account translations for {lang_code}")

    filepath = os.path.join(translations_dir, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    changed = False
    for key, value in translations[lang_code].items():
        if data.get(key) != value:
            data[key] = value
            changed = True

    if changed:
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")

print("Done adding delete account keys to JSON files.")
