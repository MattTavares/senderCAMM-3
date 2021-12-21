# senderCAMM-3
## About the Project
This is a Proof of Concept for sending PRN CAMM-GL cut files to a CAMM-3 PNC-3000 CNC Mill from Node-RED.
This method is an alternative to using the original DropOut.exe program provided by Roland and frees you from running your mill off Windows XP or earlier. 

## Requirments
* A Windows 10 machine with Node-RED installed 
* The node-red-node-serialport and node-red-contrib-simple-message-queue nodes added to the NodeRed pallete
* Native DB-9 Serial Port with working CTS/RTS Hardware Flow Control
* A valid PRN cut file (An example for cutting the text "CNC" at 2mm/s feed rate and .5mm passes is included)

     (other Operating Systems and configurations may work but are untested as of yet)

## Installation and Use
1. Install Node-RED as per the default instructions provided at https://nodered.org/docs/getting-started/windows
2. Add the node-red-node-serialport and node-red-contrib-simple-message-queue to your Node-RED Pallete
3. Import the Camm3-Sender.json flow into your running instance of Node-RED
4. Double Click the "Trigger Milling Start" node to edit it and change C:\out\1001.prn to your PRN cut file location
5. Double Click the COM1 node and then click the Pencil icon and change the COM port to match your setup
6. Click the Deploy flow button at the top right to save your changes and apply them
7. Turn on and prepare the Mill for Cutting (Generally set Z0 and Home at the front left top origin of the stock)
8. Ensure the Mill is out of "Manual" mode and ready for cutting to begin
9. Be ready to press the Emergency Stop button on the Mill if something goes wrong
10. Single Click the "Trigger Milling Start" button to begin sending your Cut code

## Disclaimer
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
