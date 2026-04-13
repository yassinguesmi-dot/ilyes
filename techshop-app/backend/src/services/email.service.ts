import nodemailer from 'nodemailer';

type SendEmailArgs = {
  to: string;
  subject: string;
  text: string;
  html?: string;
};

function getTransport() {
  const host = process.env.SMTP_HOST;
  const portRaw = process.env.SMTP_PORT;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !portRaw || !user || !pass) return null;

  const port = Number(portRaw);
  const secure = port === 465;

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });
}

export async function sendEmail(args: SendEmailArgs): Promise<void> {
  const from = process.env.EMAIL_FROM ?? 'no-reply@techshop.local';
  const transport = getTransport();

  if (!transport) {
    console.log('[email:dev]', { from, ...args });
    return;
  }

  await transport.sendMail({
    from,
    to: args.to,
    subject: args.subject,
    text: args.text,
    html: args.html,
  });
}

export async function sendPasswordResetEmail(to: string, resetUrl: string): Promise<void> {
  const subject = 'Réinitialisation du mot de passe TechShop';
  const text = `Pour réinitialiser votre mot de passe, ouvrez ce lien : ${resetUrl}`;
  const html = `<p>Pour réinitialiser votre mot de passe, cliquez ici :</p><p><a href="${resetUrl}">${resetUrl}</a></p>`;
  await sendEmail({ to, subject, text, html });
}
