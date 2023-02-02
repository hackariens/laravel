describe('template spec', () => {
  it('passes', () => {
    cy.visit('https://laravel.traefik.me');
    cy.screenshot('first-page');
  })
})